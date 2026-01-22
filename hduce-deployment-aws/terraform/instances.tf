data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "databases" {
  ami           = coalesce(var.ami_id, data.aws_ami.amazon_linux_2023.id)
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.hduce_main.id]

  tags = {
    Name = var.instance_names[0]
    Role = "databases"
  }

  user_data = filebase64("${path.module}/scripts/instance1-databases.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }
}

resource "aws_instance" "core_services" {
  ami           = coalesce(var.ami_id, data.aws_ami.amazon_linux_2023.id)
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_ids[1]
  vpc_security_group_ids = [aws_security_group.hduce_main.id]

  depends_on = [aws_instance.databases]

  tags = {
    Name = var.instance_names[1]
    Role = "microservices"
  }

  user_data = filebase64("${path.module}/scripts/instance2-services.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }
}

resource "aws_instance" "frontend" {
  ami           = coalesce(var.ami_id, data.aws_ami.amazon_linux_2023.id)
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_ids[2]
  vpc_security_group_ids = [aws_security_group.hduce_main.id]
  associate_public_ip_address = true

  depends_on = [aws_instance.databases, aws_instance.core_services]

  tags = {
    Name = var.instance_names[2]
    Role = "frontend"
  }

  user_data = filebase64("${path.module}/scripts/instance3-frontend.sh")

  root_block_device {
    volume_size = 15
    volume_type = "gp3"
    encrypted   = true
  }
}

resource "aws_instance" "monitoring" {
  ami           = coalesce(var.ami_id, data.aws_ami.amazon_linux_2023.id)
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_ids[3]
  vpc_security_group_ids = [aws_security_group.hduce_main.id]

  tags = {
    Name = var.instance_names[3]
    Role = "monitoring"
  }

  user_data = filebase64("${path.module}/scripts/instance4-monitoring.sh")

  root_block_device {
    volume_size = 15
    volume_type = "gp3"
    encrypted   = true
  }
}

resource "aws_instance" "iot" {
  ami           = coalesce(var.ami_id, data.aws_ami.amazon_linux_2023.id)
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_ids[4]
  vpc_security_group_ids = [aws_security_group.hduce_main.id]

  tags = {
    Name = var.instance_names[4]
    Role = "iot"
  }

  user_data = filebase64("${path.module}/scripts/instance5-iot.sh")

  root_block_device {
    volume_size = 15
    volume_type = "gp3"
    encrypted   = true
  }
}
