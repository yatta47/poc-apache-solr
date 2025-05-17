data "aws_vpc" "my_vpc" {
  filter {
    name   = "tag:Name"
    values = ["MyVPC"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.my_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["PublicSubnet1", "PublicSubnet2"]
  }
}

data "aws_caller_identity" "this" {}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.*-x86_64"]
  }
}