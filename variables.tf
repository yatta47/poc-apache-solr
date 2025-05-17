variable "region" {
  type        = string
  default     = "ap-northeast-1"
  description = "aws region"
}

variable "instance_type" {
  description = "EC2 instance type for Solr"
  type        = string
  default     = "t3.micro"
}

variable "data_snapshot_id" {
  description = "Optional snapshot ID for Solr data volume. If empty, a new blank volume is created."
  type        = string
  default     = ""
}

variable "data_volume_size" {
  description = "Size of the Solr data volume in GiB"
  type        = number
  default     = 10
}

variable "ssh_key_name" {
  description = "作成する KeyPair の名前"
  type        = string
  default     = "ec2_ssh_key"
}