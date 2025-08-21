resource "aws_vpc" "rds_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "wofai-rds"
  }
}

resource "aws_subnet" "wofai_rds_subnet1" {
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  vpc_id            = aws_vpc.rds_vpc.id
  map_public_ip_on_launch = true

  tags = {
    Name = "wofai_rds_subnet1"
  }
}

resource "aws_subnet" "wofai_rds_subnet2" {
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  vpc_id            = aws_vpc.rds_vpc.id
  map_public_ip_on_launch = true

  tags = {
    Name = "wofai_rds_subnet2"
  }
}

resource "aws_internet_gateway" "wofai-rds-igw" {
  vpc_id = aws_vpc.rds_vpc.id

  tags = {
    Name = "wofai-rds-igw"
  }
}

resource "aws_route_table" "wofai_rds_rt" {
  vpc_id = aws_vpc.rds_vpc.id

  tags = {
    Name = "wofai_rds_rt"
  }
}

resource "aws_route" "wofai_rds_route" {
  route_table_id         = aws_route_table.wofai_rds_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.wofai-rds-igw.id
}

resource "aws_route_table_association" "wofai_rds_route_table_association_a" {
  subnet_id      = aws_subnet.wofai_rds_subnet1.id
  route_table_id = aws_route_table.wofai_rds_rt.id
}

resource "aws_route_table_association" "wofai_rds_route_table_association_b" {
  subnet_id      = aws_subnet.wofai_rds_subnet2.id
  route_table_id = aws_route_table.wofai_rds_rt.id
}

resource "aws_db_subnet_group" "wofai_rds_subnet_group" {
  name       = "wofai-rds-subnet-group"
  subnet_ids = [aws_subnet.wofai_rds_subnet1.id, aws_subnet.wofai_rds_subnet2.id]
}

resource "aws_security_group" "wofai_rds_sg" {
  name        = "wofai-rds-sg"
  vpc_id      = aws_vpc.rds_vpc.id

  tags = {
    Name = "wofai-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "wofai_rds_ingress_rule" {
  security_group_id = aws_security_group.wofai_rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 5432
  ip_protocol       = "TCP"
  to_port           = 5432
}

resource "aws_vpc_security_group_egress_rule" "wofai_rds_egress_rule" {
  security_group_id = aws_security_group.wofai_rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}

resource "aws_ssm_parameter" "wofai_rds_ssm_parameter" {
  name  = "wofai_rds_password"
  type  = "String"
  value = random_password.wofai_rds_password.result
}

resource "random_password" "wofai_rds_password" {
  length  = 16
  special = true
  override_special = "!#$%&()*+,-.:;<=>?[]^_{|}~"
}

resource "aws_db_instance" "wofai_rds_db_instance" {
  allocated_storage    = 10
  db_name              = "competition_data_db"
  engine               = "postgres"
  engine_version       = "16.6"
  instance_class       = "db.r5.large"
  username             = "wofais_user"
  password             = aws_ssm_parameter.wofai_rds_ssm_parameter.value
  parameter_group_name = "default.postgres16"
  skip_final_snapshot  = true
  publicly_accessible  = true
  db_subnet_group_name = aws_db_subnet_group.wofai_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.wofai_rds_sg.id]
}