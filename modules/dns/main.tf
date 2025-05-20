/*
This module manages DNS records for a domain registered with Namecheap.
It creates:
- An A record pointing the root domain ("@") to an IP address
- A CNAME record pointing "www" to a target hostname (e.g., Cloudflare Pages)
*/

terraform {
  required_providers {
    namecheap = {
      source  = "namecheap/namecheap"
      version = "~> 2.0"
    }
  }
}

resource "namecheap_domain_records" "module_domain" {
  domain     = var.domain
  mode       = "OVERWRITE"
  email_type = "NONE"

  record {
    hostname = var.CNAME_hostname
    type     = "CNAME"
    address  = var.CNAME_address
    ttl      = var.time_to_live
  }

  record {
    hostname = var.A_record_hostname
    type     = "A"
    address  = var.A_record_address
    ttl      = var.time_to_live
  }
}
