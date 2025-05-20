variable "domain" {
  description = "The domain name to configure DNS for"
  type        = string
}

variable "CNAME_address" {
  description = <<-EOF
    Address for the www CNAME record. Use a fully qualified domain, with a 'dot' at the 
    end. E.g. `smallbusinesscontracts.ca.`
    EOF
  type = string
}

variable "A_record_address" {
  description = "Address for the root A record"
  type        = string
}

variable "time_to_live" {
  description = "TTL (time to live, an integer representing seconds) for DNS records"
  type        = number
}

variable "CNAME_hostname" {
  description = "E.g. 'www.staging' or just 'www'"
  type        = string
}

variable "A_record_hostname" {
  description = "E.g. '@' or 'staging'"
  type        = string
}
