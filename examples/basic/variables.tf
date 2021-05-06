variable "name_prefix" {
  type    = string
  default = "concourse-basic-example"
}

variable "packer_ami" {
  type    = string
  default = "ami-063d4ab14480ac177"
}

variable "concourse_admin_password" {
  type    = string
  default = "dolphins"
}

variable "postgres_password" {
  type    = string
  default = "dolphins"
}

variable "region" {
  type    = string
  default = "eu-west-1"
}
