
variable "tags" {
  type = map(string)
  default = {
    Environment = "production"
    Project     = "n8n-evolution-typebot"
  }
}

variable "aws_provider" {
  type = object({
    region = string,
    assume_role = object({
      role_arn = string
    })
  })

  default = {
    region = "us-east-1"
    assume_role = {
      role_arn = "arn:aws:iam::148761658767:role/TerraformAssumeRole"
    }
  }
}

variable "vpc" {
  type = object({
    name                     = string
    cidr_block               = string
    internet_gateway_name    = string
    public_route_table_name  = string
    private_route_table_name = string
    public_subnets = list(object({
      name                    = string
      cidr_block              = string
      availability_zone       = string
      map_public_ip_on_launch = bool
    })),
    private_subnets = list(object({
      name                    = string
      cidr_block              = string
      availability_zone       = string
      map_public_ip_on_launch = bool
    }))
  })
  default = {
    cidr_block               = "10.0.0.0/24"
    name                     = "vpc-n8n-evolution-typebot"
    internet_gateway_name    = "internet-gateway"
    public_route_table_name  = "public-route-table"
    private_route_table_name = "private-route-table"
    public_subnets = [{
      name                    = "public-subnet-us-east-1a"
      cidr_block              = "10.0.0.0/26"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true
      },
      {
        name                    = "public-subnet-us-east-1b"
        cidr_block              = "10.0.0.64/26"
        availability_zone       = "us-east-1b"
        map_public_ip_on_launch = true
    }]
    private_subnets = [{
      name                    = "private-subnet-us-east-1a"
      cidr_block              = "10.0.0.128/26"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = false
      },
      {
        name                    = "private-subnet-us-east-1b"
        cidr_block              = "10.0.0.192/26"
        availability_zone       = "us-east-1b"
        map_public_ip_on_launch = false
    }]
  }
}

variable "aws_instance_name" {
  description = "Name of the EC2 instance"
  default     = "n8n-evolution-typebot"
}
