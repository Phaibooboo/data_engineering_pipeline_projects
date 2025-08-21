# Iam role for redshift 
resource "aws_iam_role" "redshift_role" {
  name = "wofai_redshift_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "wofai_policy" {
  name = "wofai_policy"
  role = aws_iam_role.redshift_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",

        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

#vpc
resource "aws_vpc" "redshift_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "wofai_redshift_vpc"
  }
}

#subnets and subnet group
resource "aws_subnet" "wofai_subnet1" {
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  vpc_id            = aws_vpc.redshift_vpc.id

  tags = {
    Name = "wofai_subnet1"
  }
}

resource "aws_subnet" "wofai_subnet2" {
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  vpc_id            = aws_vpc.redshift_vpc.id

  tags = {
    Name = "wofai_subnet2"
  }
}

resource "aws_redshift_subnet_group" "wofai_subnet_group" {
  name       = "wofai-subnet-group"
  subnet_ids = [aws_subnet.wofai_subnet1.id, aws_subnet.wofai_subnet2.id]

}

#security group, ingress and egress rules
resource "aws_security_group" "wofai_sg" {
  name   = "wofai_sg"
  vpc_id = aws_vpc.redshift_vpc.id

  tags = {
    Name = "wofai_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "wofai_ingress" {
  security_group_id = aws_security_group.wofai_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 5439
  ip_protocol       = "tcp"
  to_port           = 5439
}

resource "aws_vpc_security_group_egress_rule" "wofai_egress" {
  security_group_id = aws_security_group.wofai_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_internet_gateway" "wofai_internet_gateway" {
  vpc_id = aws_vpc.redshift_vpc.id

  tags = {
    Name = "wofai_internet_gateway"
  }
}

resource "aws_route" "wofai_route" {
  route_table_id         = aws_route_table.wofai_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.wofai_internet_gateway.id
}

resource "aws_route_table" "wofai_route_table" {
  vpc_id = aws_vpc.redshift_vpc.id

  tags = {
    Name = "wofai_route_table"
  }
}

resource "aws_route_table_association" "wofai_route_table_association_a" {
  subnet_id      = aws_subnet.wofai_subnet1.id
  route_table_id = aws_route_table.wofai_route_table.id
}
resource "aws_route_table_association" "wofai_route_table_association_b" {
  subnet_id      = aws_subnet.wofai_subnet2.id
  route_table_id = aws_route_table.wofai_route_table.id
}

resource "aws_ssm_parameter" "wofai_ssm_parameter" {
  name  = "wofai_redshift_password"
  type  = "String"
  value = random_password.wofai_password.result
}

resource "random_password" "wofai_password" {
  length  = 16
  special = true
}


# redshift cluster
resource "aws_redshift_cluster" "wofai_aws_redshift_cluster" {
  cluster_identifier        = "wofais-redshift-cluster"
  database_name             = "wofai_db"
  master_username           = "wofai_user"
  master_password           = aws_ssm_parameter.wofai_ssm_parameter.value
  node_type                 = "ra3.large"
  cluster_type              = "single-node"
  publicly_accessible       = "true"
  iam_roles                 = [aws_iam_role.redshift_role.arn]
  vpc_security_group_ids    = [aws_security_group.wofai_sg.id]
  cluster_subnet_group_name = aws_redshift_subnet_group.wofai_subnet_group.name

  tags = {
    Name = "wofai_redshift_cluster"
  }
}



