#!/bin/bash
# To run manually: 
# Copy and paste the value of iptables_call.txt and run that. E.g.
# `rds_elastic_net_ip="40.176.157.219" subnets="<...>" vpc_cidr_block="<...>" ./iptables.sh`
# "iptables_call.txt" is re-created on every run of this file and saves the values the 
# file was called with, for convenient re-use.

# Note: If any of the logs are running, then it could mean packets are being 
# rejected that shouldn't be (or that unexpected legitimate or illegitimate activity is 
# happening).

# Store the values that this was called with, for easy reproduction again. (The values
# would initially come from running `terraform apply` on main-app/main.tf)
# `rds_elastic_net_ip` -> the "Elastic network interface" from my EC2 to my RDS
# `subnets` -> the CIDR blocks associated with all of my subnets
# `vpc_cidr_block` -> the CIDR block associated with my VPC
# Note: I am unsure how stable these CIDR blocks will be.
echo "rds_elastic_net_ip=\"$rds_elastic_net_ip\" subnets=\"$subnets\" vpc_cidr_block=\"$vpc_cidr_block\" api_net_interface=\"$API_NET_INTERFACE_NAME\" ./iptables.sh" > iptables_call.txt

# api_net_interface=api-network-if  # WHAT IS api-network-if ?????? (a string value for the name??)

# Conditionally install iptables-persistent
if ! dpkg -l | grep netfilter-persistent; then
    apt-get update && apt-get install -y netfilter-persistent
fi

command -v jq >/dev/null 2>&1 || { sudo apt-get update && sudo apt-get install -y jq; }

# First flush existing DOCKER-USER chain rules to avoid the default RETURN
iptables -F DOCKER-USER

# Allow traffic from the container, through api-network, out to the RDS. Note that you 
# can also use `-d the RDS endpoint (allexemdb3.czeq2c62g1ex.us-east-2.rds.amazonaws.com) 
# here and it works out (at present) to the same thing. But I am 
# unsure whether the ip address associated with the RDS endpoint will be stable and 
# relable. The `iptables` docs say about `-s`/`d`, "specifying any name to be resolved  
# with a remote query such as DNS is a really bad idea".
iptables -A DOCKER-USER -i "$api_net_interface" -p tcp -d "$rds_elastic_net_ip" --dport 5432 -j ACCEPT
# Allow traffic from RDS to the network and into the container
iptables -A DOCKER-USER -o "$api_net_interface" -s "$rds_elastic_net_ip" -j ACCEPT
# Note: these rules could be narrowed by adding `-d/-s <the_contain_ip> --dport 8000`.  
# To do that I would have to create a subnet during network creation with a predefined 
# ip address and refer to that in the compose file. 
# See https://stackoverflow.com/questions/27937185/assign-static-ip-to-docker-container

# Add conntrack rules below others to avoid unnecessary performance degradation of that 
# w/ docker.
# Accept outbound established and related connections on api-network
iptables -A DOCKER-USER -i "$api_net_interface" -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# Accept inbound established and related connections on api-network
iptables -A DOCKER-USER -o "$api_net_interface" -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Note: The below two rules confuse me. Consider this truncated log output from
# `iptables -A DOCKER-USER -i "$api_net_interface" -p tcp -m conntrack --ctreplsrc 172.31.2.73 -j ACCEPT`:
# `DOCKER LOG 4:IN=api-network-if OUT=enX0 ... SRC=172.18.0.2 DST=172.31.2.73`
# I don't understand how `--ctorigdst` could be $rds_elastic_net_ip, where the rule shows RDS
# is the destination. It seems like either the above or the below rule should have no 
# effect, as they are the same except the use of --ctreplsrc/--ctorigdst. But logging 
# shows they both are operative.
iptables -A DOCKER-USER -i "$api_net_interface" -p tcp -m conntrack --ctorigdst "$rds_elastic_net_ip" --ctorigdstport 5432 -j ACCEPT
iptables -A DOCKER-USER -i "$api_net_interface" -p tcp -m conntrack --ctreplsrc "$rds_elastic_net_ip" --ctorigdstport 5432 -j ACCEPT
# Note: My comments about the above rules apply to the below two.
iptables -A DOCKER-USER -o "$api_net_interface" -p tcp -m conntrack --ctorigdst "$rds_elastic_net_ip" -j ACCEPT
iptables -A DOCKER-USER -o "$api_net_interface" -p tcp -m conntrack --ctreplsrc "$rds_elastic_net_ip" -j ACCEPT

# AWS S3 stuff. This will result in a lot of rules.
aws_ip_ranges_path="/tmp/aws-ip-ranges.json"
rm -f "$aws_ip_ranges_path"
# Fetch the IP ranges and save to a file
curl -sS https://ip-ranges.amazonaws.com/ip-ranges.json -o "$aws_ip_ranges_path"
# Source: https://docs.aws.amazon.com/vpc/latest/userguide/aws-ip-work-with.html#filter-ip-ranges-ipv4-service-region
ip_addresses=($(jq -r '.prefixes[] | select(.region=="ca-west-1") | select(.service=="S3") | .ip_prefix' < "$aws_ip_ranges_path"))
rm -f "$aws_ip_ranges_path"  # remove when done, as it's a large file

# NOTE: The checks here made sense for us-east-2. But ca-west-1 has only one ip range. 
# Consider: log instead of exiting?
# Also: determine how to manage a cron job to look for changes to this. (Needs to 
# recognize a before and after (?))

# # Check that there are at least 10 ip ranges
# aws_min_lines=10
# if [[ ${#ip_addresses[@]} -lt $aws_min_lines ]]; then
#     echo "WARNING: Fewer than $aws_min_lines S3 IPs found in AWS IP list." >&2
#     exit 1
# fi

# # Spot check for an expected IP range
# aws_spotcheck_ip="52.219.212.0/22"  # A known IP range as of writing
# if [[ ! " ${ip_addresses[*]} " =~ $aws_spotcheck_ip ]]; then
#     echo "WARNING: Expected S3 IP prefix $aws_spotcheck_ip not found in AWS IP list." >&2
#     exit 1
# fi

for ip in "${ip_addresses[@]}"; do
    echo "adding to $ip"
    sudo iptables -A DOCKER-USER -o "$api_net_interface" -s "$ip" -j LOG --log-prefix "DOCKER DEBUG ACCEPT 1: " --log-level 4
    sudo iptables -A DOCKER-USER -i "$api_net_interface" -d "$ip" -j LOG --log-prefix "DOCKER DEBUG ACCEPT 2: " --log-level 4
    sudo iptables -A DOCKER-USER -o "$api_net_interface" -s "$ip" -j ACCEPT
    sudo iptables -A DOCKER-USER -i "$api_net_interface" -d "$ip" -j ACCEPT
done

# Stripe stuff. This will result in a lot of rules.
stripe_ips_path="/tmp/stripe-ips.txt"
spotcheck_ids=("13.112.224.240" "13.115.13.148" "13.210.129.177")
min_lines=50

rm -f "$stripe_ips_path"
# Fetch the IP list and save to a file
curl -sS https://stripe.com/files/ips/ips_api.txt -o "$stripe_ips_path"

# Check that the file exists and has at least min_lines
if [[ ! -f "$stripe_ips_path" ]] || [[ $(wc -l < "$stripe_ips_path") -lt $min_lines ]]; then
    echo "WARNING: IP file is missing or has fewer than $min_lines lines." >&2
    exit 1
fi

# Spot check for a few expected IPs
missing_ips=()
for ip in "${spotcheck_ids[@]}"; do
    if ! grep -q "$ip" "$stripe_ips_path"; then
        missing_ips+=("$ip")
    fi
done

# Log a warning if any expected IPs are missing
if [[ ${#missing_ips[@]} -gt 0 ]]; then
    echo "WARNING: Some expected IPs are missing from the list: ${missing_ips[*]}" >&2
    exit 1
fi

# Allow communications from apis-network to potential stripe api ip addresses
# Note: Those addresses are from https://stripe.com/files/ips/ips_api.txt and there 
# should be quite a few (like 100-300-ish, eyballing it). More potential urls or 
# endpoints can be found at https://docs.stripe.com/ips
while read -r ip; do
    iptables -A DOCKER-USER -i "$api_net_interface" -d "$ip" -p tcp -j ACCEPT
    iptables -A DOCKER-USER -o "$api_net_interface" -s "$ip" -p tcp -j ACCEPT
done < "$stripe_ips_path"

rm -f "$stripe_ips_path"  # remove when done

# ACCEPT traffic out from api_net_interface to each relevant subnet (three of them)
for subnet in $subnets; do
  echo "Applying rule for subnet: $subnet"
  iptables -A DOCKER-USER -i "$api_net_interface" -d "$subnet" -j LOG --log-prefix "DOCKER DEBUG ACCEPT 3: " --log-level 4
  iptables -A DOCKER-USER -i "$api_net_interface" -d "$subnet" -j ACCEPT
done
# Note: The intention is that these should catch all possible exit ips

# Gmail / Google IP Ranges. This will result in a lot of rules.
google_ips_path="/tmp/google-ips.json"
rm -f "$google_ips_path"

# Fetch Google's published IP ranges
curl -sS "https://www.gstatic.com/ipranges/goog.json" -o "$google_ips_path"
# Extract all IPv4 prefixes (these are used by Google services including Gmail)
# TODO: I think my EC2 will only use ipv4 -- look into this.
ip_addresses=($(jq -r '.prefixes[] | select(.ipv4Prefix != null) | .ipv4Prefix' < "$google_ips_path"))

# spot check a few known Gmail-related IPs
google_spotcheck_ips=("64.233.160.0/19" "66.102.0.0/20" "74.125.0.0/16" "142.250.0.0/15" "209.85.128.0/17")
missing_google_ips=()
for ip in "${google_spotcheck_ips[@]}"; do
    if [[ ! " ${ip_addresses[*]} " =~ $ip ]]; then
        missing_google_ips+=("$ip")
    fi
done

if [[ ${#missing_google_ips[@]} -gt 0 ]]; then
    echo "WARNING: Some expected Google IPs are missing: ${missing_google_ips[*]}" >&2
    exit 1
fi

# allow traffic to Google IPs (for gmail email backend)
for ip in "${ip_addresses[@]}"; do
    echo "g.ip: $ip"
    sudo iptables -A DOCKER-USER -i "$api_net_interface" -d "$ip" -j ACCEPT
done
rm -f "$google_ips_path"  # Clean up

# This crude and blunt ACCEPT rule permits all traffic to a destination within my 
# VPC--I am reasonably confident that the CIDR block associated with my VPC will 
# exclude any possible outside ip addresses. However, this ACCEPT rule is broader than
# a lot of the more specific rules already applied. In part, I am not fully confident in
# my understanding and implementation of these iptables rules, so this is a 
# belt-and-suspenders approach.
iptables -A DOCKER-USER -i "$api_net_interface" -d "$vpc_cidr_block" -j LOG --log-prefix "DOCKER DEBUG ACCEPT 4: " --log-level 4
iptables -A DOCKER-USER -i "$api_net_interface" -d "$vpc_cidr_block" -j ACCEPT

# Before adding DROP rules, add log rules that should not run but will if there is a  
# problem with the above rules, and especially with the value of $rds_elastic_net_ip.
# Re: 172.31.0.0/16, see the note above the corresponding rule, below.
iptables -A DOCKER-USER -o "$api_net_interface" -j LOG --log-prefix "DOCKER DEBUG DROP 2: " --log-level 4
iptables -A DOCKER-USER -i "$api_net_interface" -j LOG --log-prefix "DOCKER DEBUG DROP 3: " --log-level 4

# Deny all other inbound communications (-o here means out of the docker network and to 
# the container)
iptables -A DOCKER-USER -o "$api_net_interface" -j DROP

# Deny all other outbound communications (-i here means into the docker network from the 
# container, on on out to the internet)
iptables -A DOCKER-USER -i "$api_net_interface" -j DROP

# Re-add the default docker RETURN
iptables -A DOCKER-USER -j RETURN

netfilter-persistent save
