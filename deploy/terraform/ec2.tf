provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_policy_attachment" "ec2fullaccess" {
  name = "ec2-full-access"

  users = [
    "rossjcohen@gmail.com",
  ]

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_key_pair" "ross-key" {
  key_name   = "ross-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDcn2ZZuvmaDGXX5nNQKtU/PImXqTY8iXFNwXqBsGZPCL5+JwhsTub5ACIch3R0aqoMo2K1hH4bPHkbIsrC1xW8/pxX53lnKpom/i8viSEuGWOXmTf3MgkJ1dCUTUr74pUWTaKSLkv0/P7g/GIaLZlYB5HkvghigksfoZcyVOFS282MGQtC/ceNy/q3g4k2oQv/A65pxdvVXdHLfwcb9qBi9/UWEz2WfU7ynv8SPuZ/qlzJ+9RVS80N2IX/BzT1Q8opQCtRB9anSfKTa37xIIb0S6j0/BQGe7VMavMWu4vVwL8R44DwISpV0ebBH9tfKqkMWSjTQdzsvndr9iwbI7YP ross@Chickadee"

  depends_on = [
    "aws_iam_policy_attachment.ec2fullaccess",
  ]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*",
    ]
  }

  filter {
    name = "virtualization-type"

    values = [
      "hvm",
    ]
  }

  owners = [
    "099720109477",
  ]

  # Canonical
}

resource "aws_security_group" "explore311security" {
  name        = "explore311_security"
  description = "Allow inbound traffic on notebook port and ssh port"

  ingress {
    from_port = 80
    to_port   = 8888
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  depends_on = [
    "aws_iam_policy_attachment.ec2fullaccess",
  ]
}

resource "aws_instance" "explore311" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.medium"
  key_name      = "ross-key"

  security_groups = [
    "${aws_security_group.explore311security.name}",
  ]

  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
  }

  user_data = <<EOF
#!/bin/bash
apt update
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository -y \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt update
apt install -y docker-ce
usermod -aG docker ubuntu
git clone https://github.com/BossColo/Explore311 /home/ubuntu/Explore311
chmod -R 777 /home/ubuntu/Explore311
docker build -t explore311 /home/ubuntu/Explore311/deploy/docker/
docker run -d -p 80:8888 -v /home/ubuntu/Explore311:/home/jovyan/Explore311 --rm --name jupyter explore311
EOF

  tags {
    Name = "Explore311"
  }

  depends_on = [
    "aws_key_pair.ross-key",
    "aws_security_group.explore311security",
  ]
}
