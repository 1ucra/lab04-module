data "aws_subnet" "db-subnet1" {
  filter {
    name   = "tag:Name"
    values = ["aws_subnet/db-subnet1"]
  }
}

data "aws_subnet" "db-subnet2" {
  filter {
    name   = "tag:Name"
    values = ["aws_subnet/db-subnet2"]
  }
}

data "aws_security_group" "db-sg" {

  filter {
    name = "group-id"
    values = [var.db_securityGroup_id]
  }
}

data "aws_ssm_parameter" "db-id" {
  name  = "/config/account/admin/ID"
}

data "aws_ssm_parameter" "db-pwd" {
  name  = "/config/account/admin/PWD"
}