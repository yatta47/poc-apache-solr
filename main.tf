# Security group for Solr node
resource "aws_security_group" "solr_sg" {
  name_prefix = "solr-sg-"
  vpc_id      = data.aws_vpc.my_vpc.id

  description = "Security group for Solr single-node EC2"
}

# Solr HTTP ingress rule
resource "aws_security_group_rule" "solr_http_ingress" {
  security_group_id = aws_security_group.solr_sg.id
  type              = "ingress"
  from_port         = 8983
  to_port           = 8983
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# All egress rule
resource "aws_security_group_rule" "all_egress" {
  security_group_id = aws_security_group.solr_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Single EC2 instance with an additional data volume for Solr
# Single EC2 instance with an additional data volume for Solr
resource "aws_instance" "solr" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = tolist(data.aws_subnets.public.ids)[0] # 最初のパブリックサブネットを使用
  vpc_security_group_ids = [aws_security_group.solr_sg.id]
#   key_name               = aws_key_pair.ssh.key_name
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  # Root volume (default)
  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "solr-single-node"
  }
}

# IAM Role and Instance Profile for SSM Session Manager
resource "aws_iam_role" "ssm_role" {
  name               = "solr-ssm-role"
  assume_role_policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "solr-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# Data volume for Solr (blank or from snapshot)
resource "aws_ebs_volume" "solr_data" {
  availability_zone = aws_instance.solr.availability_zone
  snapshot_id       = var.data_snapshot_id != "" ? var.data_snapshot_id : null
  size              = var.data_volume_size
  tags = {
    Name = "solr-data-volume"
  }
}

# Attach data volume to instance
resource "aws_volume_attachment" "solr_data_attach" {
  device_name  = "/dev/xvdf"
  volume_id    = aws_ebs_volume.solr_data.id
  instance_id  = aws_instance.solr.id
  force_detach = true
}
