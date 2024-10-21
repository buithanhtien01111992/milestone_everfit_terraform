#main.tf
variable "ec2_instance_type" {
  description = "EC2 instance type"
  default     = "t2.small"
}

variable "ec2_ami_id" {
  description = "EC2 AMI ID"
  default     = "ami-047126e50991d067b"
  type        = string
}

variable "rds_instance_type" {
  description = "RDS instance type"
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the RDS database"
  default     = "mydb"
}

variable "db_username" {
  description = "Username for the RDS database"
}

variable "db_password" {
  description = "Password for the RDS database"
}

resource "aws_security_group" "ec2_rds_access" {
  name = "ec2_rds_access"
  description = "Security group for EC2 to RDS access"
  vpc_id = data.aws_vpc.default_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_security_group.id]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_security_group" {
  name        = "rds_security_group"
  description = "Security group for RDS access"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet" "default_subnet" {
  vpc_id            = data.aws_vpc.default_vpc.id
  availability_zone = "ap-southeast-1a"
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

variable "keyname" {
  description = "SSH key name"
  default     = "private_key"
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.keyname
  public_key = "${tls_private_key.pk.public_key_openssh}"

  provisioner "local-exec" { 
    # Create keypair to your computer!!
    command = <<EOT
              rm -f ./${var.keyname}.pem
              echo '${tls_private_key.pk.private_key_pem}' > ./${var.keyname}.pem
              chmod 400 ${var.keyname}.pem
              EOT
  }
}

resource "aws_instance" "ec2_instance" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = data.aws_subnet.default_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_rds_access.id, aws_security_group.ping_ssh.id]
  key_name               = aws_key_pair.generated_key.key_name

    provisioner "remote-exec" {
    inline = [
        "sudo apt update",
        "sudo apt install -y nginx",
        "sudo apt install -y git",
        "sudo apt install -y python3",
        "sudo apt install -y python3-pip",
        "sudo apt install -y python3-venv",
        "sudo apt install -y mysql-client-core-8.0",
        "sudo apt install -y python-dotenv",
        "git clone https://github.com/evereux/flicket.git /home/ubuntu/flicket",
        "cd /home/ubuntu/flicket",

        # Create virtual environment
        "python3 -m venv venv",

        # Activate venv and install necessary packages
        "bash -c 'source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt || true'",

        # Verify installation of packages
        "source venv/bin/activate && pip list",

        # Tạo file config.json với các tham số từ Terraform
        "bash -c 'source venv/bin/activate && python3 -c \"import json; config = {\\\"db_type\\\": 3, \\\"db_driver\\\": \\\"pymysql\\\", \\\"db_username\\\": \\\"${var.db_username}\\\", \\\"db_password\\\": \\\"${var.db_password}\\\", \\\"db_url\\\": \\\"${aws_db_instance.rds_instance.endpoint}\\\", \\\"db_port\\\": \\\"3306\\\", \\\"db_name\\\": \\\"${var.db_name}\\\", \\\"SECRET_KEY\\\": \\\"$(openssl rand -base64 24)\\\", \\\"NOTIFICATION_USER_PASSWORD\\\": \\\"$(openssl rand -base64 24)\\\"}; open(\\\"config.json\\\", \\\"w\\\").write(json.dumps(config, indent=4))\"'",


        # Edit config.json to set the correct db_driver and remove the :3306 port in the JSON
        "sed -i 's/:3306//g' /home/ubuntu/flicket/config.json",

        # Apply Flask migrations and run the Flask app
        "bash -c 'source venv/bin/activate &&  pip install Werkzeug==2.3.6'",
        "bash -c 'source venv/bin/activate && flask db migrate'",
        "bash -c 'source venv/bin/activate && flask db upgrade'",
        "bash -c 'source venv/bin/activate && nohup flask run --host=0.0.0.0 --port=5000 &'"
    ]
    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = file("${path.module}/../private_key.pem")
        host        = self.public_ip
    }
    }
}

resource "aws_db_instance" "rds_instance" {
  engine                  = "mysql"
  instance_class          = var.rds_instance_type
  username                = var.db_username
  password                = var.db_password
  allocated_storage       = 20
  storage_type            = "gp2"
  db_name                 = var.db_name
  vpc_security_group_ids  = [aws_security_group.rds_security_group.id]
  skip_final_snapshot     = "true"
  backup_retention_period = 0
}

resource "aws_security_group" "ping_ssh" {
  name = "ec2_ping_ssh"

  ingress {
    //ICMP ping
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { 
    //SSH
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {  
    //Allow all outbound ports
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "ssh_ec2_instance" {
  value = "ssh -i '${var.keyname}.pem' ubuntu@${aws_instance.ec2_instance.public_ip}"
}

output "rds_instance" {
  value = aws_db_instance.rds_instance.endpoint
}