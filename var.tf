variable "publicSubnetCount" {
  type = number
  default = 2 
}

variable "AZ" {
  type = list(string)
  default = [ "us-east-1a", "us-east-1b" ]
}