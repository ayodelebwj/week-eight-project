terraform {
  backend "local" {
    # bucket = "techbleat"
    # key = "env/dev"
    # region = "us-east-2"
    # encrypt = true
    path = "/tmp/terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "techbleatvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "techbleatvpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.techbleatvpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.techbleatvpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"

  tags = {
    Name = "public_1"
  }
}



resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.techbleatvpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2b"

  tags = {
    Name = "public-2"
  }
}


resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.techbleatvpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "private-1"
  }
}


resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.techbleatvpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "private-2"
  }
}


resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.allocation_id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.igw]


  tags = {
    Name = "nat"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.techbleatvpc.id

  tags = {
    Name = "public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.techbleatvpc.id

  tags = {
    Name = "private"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id

}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "public_rt_assoc_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_rt_assoc_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "private_rt_assoc_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}


resource "aws_route_table_association" "private_rt_assoc_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "nginx_sg" {
  name        = "nginx_sg"
  description = "Security group for nginx web server"
  vpc_id      = aws_vpc.techbleatvpc.id

  # Allow SSH from your IP only
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "HTTPS from ALB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion_sg"
  }
}

resource "aws_instance" "bastion" {
  instance_type               = "t3.micro"
  ami                         = "ami-0f5fcdfbd140e4ab7"
  key_name                    = "ohio-kp"
  subnet_id                   = aws_subnet.public_1.id
  security_groups             = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
}

resource "aws_security_group" "private_host_sg" {
  name        = "private_host_sg"
  description = "Security group for private host"
  vpc_id      = aws_vpc.techbleatvpc.id

  # Allow SSH from your IP only
  ingress {
    description     = "SSH from my IP"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]

  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private_host_sg"
  }
}


resource "aws_instance" "private_host" {
  instance_type               = "t3.micro"
  ami                         = "ami-0f5fcdfbd140e4ab7"
  key_name                    = "ohio-kp"
  subnet_id                   = aws_subnet.private_1.id
  security_groups             = [aws_security_group.private_host_sg.id]
  associate_public_ip_address = false
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.techbleatvpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.techbleatvpc.id
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}