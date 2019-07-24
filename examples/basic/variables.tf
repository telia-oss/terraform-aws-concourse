variable "name_prefix" {
  type    = string
  default = "concourse-basic-example"
}

variable "packer_ami" {
  type = string
}

variable "postgres_password" {
  type    = string
  default = "dolphins"
}

variable "region" {
  type    = string
  default = "eu-west-1"
}
