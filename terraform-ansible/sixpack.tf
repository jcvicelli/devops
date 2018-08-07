variable "project" {
  description = "This project's name"
  default     = "sixpack"
}

variable "profile" {
  description = "AWS Profile configured in your credentials file"
}

variable "region" {
  description = "AWS Region"
}

variable "ami_id" {
  description = "AWS EC2 ami id"
}

variable "key_name" {
  description = "AWS ssh keyname configured in EC2"
}

variable "certificate_arn" {
  description = "AWS https certificate"
}

variable "private_key_path" {
  description = "Path the ssh private key file to log into the ec2 instance"
}

variable "centos_version" {
  description = "CentOS version"
  default     = "7"
}

variable "cost" {
  description = "Cost"
}

variable "Project" {
  description = "Project"
}

variable "zone" {
  description = "Route53 Zone name"
}

variable "vpc_id" {
  description = "AWS VPC Id"
}

variable "secretsmanager_arn" {
  description = "Secretmanager ARN for Sixpack."
}

provider "aws" {
  profile = "${var.profile}"
  region  = "${var.region}"
}

terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "sixpack/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_secretsmanager_secret" "sixpack-secrets" {
  arn = "${var.secretsmanager_arn}"
}

data "aws_secretsmanager_secret_version" "sixpack-secrets" {
  secret_id = "${var.secretsmanager_arn}"
}

resource "local_file" "aws_secrets" {
  content  = "${data.aws_secretsmanager_secret_version.sixpack-secrets.secret_string}"
  filename = "Ansible/templates/aws_secrets.json"
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "sixpacksg" {
  name        = "sixpack-sg"
  description = "Used in the terraform sixpack"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Redis access from anywhere
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "sixpack-server" {
  ami           = "${var.ami_id}"
  instance_type = "t2.medium"
  key_name      = "${var.key_name}"

  tags {
    Name              = "sixpack server"
    costBucket        = "${var.cost}"
    costBucketProject = "${var.Project}"
  }

  connection {
    user        = "centos"
    private_key = "${file(var.private_key_path)}"
  }

  vpc_security_group_ids = ["${aws_security_group.sixpacksg.id}"]

  provisioner "local-exec" {
    command = <<EOT
                sleep 120
                ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u centos --private-key '${var.private_key_path}' -i '${aws_instance.sixpack-server.public_ip}', Ansible/docker.yml
                sleep 60
                ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u centos --private-key '${var.private_key_path}' -i '${aws_instance.sixpack-server.public_ip}', Ansible/redis.yml
                sleep 60
                ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u centos --private-key '${var.private_key_path}' -i '${aws_instance.sixpack-server.public_ip}', Ansible/newrelic.yml
                sleep 60
                ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u centos --private-key '${var.private_key_path}' -i '${aws_instance.sixpack-server.public_ip}', Ansible/sixpack.yml

                EOT
  }
}

resource "aws_alb" "sixpack-alb" {
  tags {
    Bucket        = "${var.Bucket}"
    Project = "${var.Project}"
  }

  name            = "sixpack-alb"
  security_groups = ["${aws_security_group.sixpacksg.id}"]
  subnets         = ["${aws_instance.sixpack-server.subnet_id}", "subnet-123", "subnet-123"]
  internal        = false
  idle_timeout    = "300"
}

resource "aws_alb_listener" "sixpack-alb-listener" {
  load_balancer_arn = "${aws_alb.sixpack-alb.arn}"
  port              = "5000"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.sixpack-alb-tg-backend.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "sixpack-alb-listener-https" {
  load_balancer_arn = "${aws_alb.sixpack-alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "${var.certificate_arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.sixpack-alb-tg.arn}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "sixpack-alb-tg" {
  name     = "sixpack-alb-tg"
  port     = "5001"
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 60
    interval            = 120
    path                = "/"
    port                = "5001"
  }
}

resource "aws_alb_target_group" "sixpack-alb-tg-backend" {
  name     = "sixpack-alb-tg-backend"
  port     = "5000"
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 60
    interval            = 120
    path                = "/"
    port                = "5001"
    matcher             = "200"
  }
}

resource "aws_alb_target_group_attachment" "sixpack_physical_external" {
  target_group_arn = "${aws_alb_target_group.sixpack-alb-tg.arn}"
  target_id        = "${aws_instance.sixpack-server.id}"
  port             = 5001
}

resource "aws_alb_target_group_attachment" "sixpack_physical_external_backend" {
  target_group_arn = "${aws_alb_target_group.sixpack-alb-tg-backend.arn}"
  target_id        = "${aws_instance.sixpack-server.id}"
  port             = 5000
}

data "aws_route53_zone" "abcde" {
  name         = "${var.zone}"
  private_zone = false
}

resource "aws_route53_record" "lt-sixpack" {
  zone_id = "${data.aws_route53_zone.lookitsuni.zone_id}"
  name    = "sixpack.${data.aws_route53_zone.abcde.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_alb.sixpack-alb.dns_name}"]
}

output "Sixpack public IP" {
  value = "${aws_instance.sixpack-server.public_ip}"
}
