terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = var.aws_region # Using the variable for region!
}
# --- VPC Definition ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true # Important for ALB and other services
  enable_dns_support   = true # Also important for DNS resolution within VPC
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public" {
  # The 'count' meta-argument allows us to create multiple identical resources
  # based on a list. Here, we're creating one public subnet for each CIDR
  # defined in var.public_subnet_cidrs.
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id                      # Reference the VPC we just created
  cidr_block              = var.public_subnet_cidrs[count.index] # Get CIDR from list
  availability_zone       = var.availability_zones[count.index]  # Get AZ from list
  map_public_ip_on_launch = true                                 # Instances in this subnet will get a public IP
  tags = {
    Name = "${var.vpc_name}-public-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id # Attach it to our VPC
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}
# --- Route Table for Public Subnets ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  # This route sends all outbound traffic (0.0.0.0/0) to the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}
# --- Associate Public Subnets with the Public Route Table ---
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id # Reference each public subnet
  route_table_id = aws_route_table.public.id         # Reference the public route table
}

resource "aws_instance" "web_server" {
  ami           = var.instance_ami
  instance_type = var.instance_type
  key_name      = var.instance_key_name
  subnet_id     = aws_subnet.public[0].id # Place it in the first public subnet

  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_http.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Terraform on $(hostname -f)!</h1>" > /var/www/html/index.html
              EOF
  tags = {
    Name = var.instance_name
  }
}
# --- Output the Public IP of our EC2 instance ---
output "web_server_public_ip" {
  description = "The public IP address of the web server instance."
  value       = aws_instance.web_server.public_ip
}

resource "aws_security_group" "allow_ssh" {
  name        = "${var.vpc_name}-allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id # Attach to our VPC
  ingress {
    description = "SSH from VPC or specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # IMPORTANT: In a real environment, restrict this to your office IP or VPN IP.
    # "0.0.0.0/0" means from anywhere, which is convenient for testing but less secure.
    # Using your public IP: ["YOUR_PUBLIC_IP/32"]
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow all outbound traffic by default for now (common for web servers)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.vpc_name}-allow-ssh"
  }
}
# --- Security Group for HTTP Access ---
resource "aws_security_group" "allow_http" {
  name        = "${var.vpc_name}-allow-http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress { # Outbound access to anywhere
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.vpc_name}-allow-http"
  }
}
resource "aws_security_group" "alb" {
  name        = "${var.vpc_name}-alb-sg"
  description = "Allow HTTP traffic to ALB from anywhere"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "Allow HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow all IPv4 traffic
  }
  ingress {
    description = "Allow HTTPS from Internet (placeholder)"
    from_port   = 443 # Placeholder for future HTTPS setup
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress { # ALB needs to talk back to the internet and to instances
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.vpc_name}-alb-sg"
  }
}
# --- IMPORTANT: Modify the 'allow_http' SG to allow traffic ONLY from the ALB's SG ---
# We're making our EC2 instances only reachable via the ALB, not directly from the internet.
resource "aws_security_group" "allow_http" {
  name        = "${var.vpc_name}-allow-http"
  description = "Allow HTTP inbound traffic from ALB"
  vpc_id      = aws_vpc.main.id
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # Allow traffic only from the ALB's SG!
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.vpc_name}-allow-http"
  }
}

resource "aws_lb_target_group" "web_app" {
  name_prefix = "web-app-tg-" # Short prefix for the name
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  health_check {
    path                = "/" # Check the root path of our web server
    protocol            = "HTTP"
    matcher             = "200" # Expect a 200 OK response
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = {
    Name = "${var.vpc_name}-web-app-tg"
  }
}

resource "aws_lb" "main" {
  name_prefix        = var.alb_name_prefix
  internal           = false # This is an internet-facing ALB
  load_balancer_type = "application"
  # Place ALB in our public subnets for internet access
  subnets         = [for s in aws_subnet.public : s.id] # A neat trick to get all public subnet IDs
  security_groups = [aws_security_group.alb.id]         # Attach the ALB's own security group
  tags = {
    Name = "${var.vpc_name}-alb"
  }
}
# --- ALB Listener (HTTP Port 80) ---
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn # Reference the ALB's ARN
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_app.arn # Forward traffic to our target group
  }
}

resource "aws_launch_template" "web_app" {
  name_prefix   = "${var.vpc_name}-web-app-lt-"
  image_id      = var.instance_ami
  instance_type = var.instance_type
  key_name      = var.instance_key_name
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_http.id # Now only allows traffic from ALB!
  ]
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Terraform on $(hostname -f)!</h1>" > /var/www/html/index.html
              EOF
  ) # User data needs to be base64 encoded for launch templates
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.instance_name}-ASG-Instance"
    }
  }
}

resource "aws_autoscaling_group" "web_app" {
  name                = "${var.vpc_name}-web-app-asg"
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  health_check_type   = "ELB"                               # ASG uses ALB's health checks
  vpc_zone_identifier = [for s in aws_subnet.public : s.id] # ASG deploys into these subnets
  launch_template {
    id      = aws_launch_template.web_app.id
    version = "$Latest" # Always use the latest version of the launch template
  }
  target_group_arns = [aws_lb_target_group.web_app.arn] # Attach ASG to our target group
  tags = [                                              # Tags for ASG itself AND instances launched by ASG
    {
      key                 = "Name"
      value               = "${var.vpc_name}-web-app-asg-instance"
      propagate_at_launch = true
    },
  ]
}
resource "aws_route53_zone" "main_public" {
  name = var.domain_name
  tags = {
    Name = "${var.domain_name}-public-zone"
  }
}
resource "aws_route53_record" "web_app_alias" {
  zone_id = aws_route53_zone.main_public.zone_id # Reference the hosted zone ID
  # If using data source: zone_id = data.aws_route53_zone.selected.zone_id
  name = "${var.subdomain_name}.${var.domain_name}" # e.g., www.yourdomain.com
  type = "A"                                        # "A" record maps a domain to an IPv4 address (or an Alias target)
  alias {
    name                   = aws_lb.main.dns_name # The ALB's DNS name
    zone_id                = aws_lb.main.zone_id  # The ALB's Hosted Zone ID
    evaluate_target_health = true                 # Recommended: Route 53 considers target health
  }
  tags = {
    Name = "${var.subdomain_name}.${var.domain_name}-alias"
  }
}

resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "${var.vpc_name}-codepipeline-artifacts-${random_string.suffix.id}" # Unique bucket name
  # Add a random suffix to ensure unique bucket name
  # Need to define 'random_string.suffix' resource below if you use it!
  # Recommended: Enable versioning for artifacts
  versioning {
    enabled = true
  }
  # Recommended: Enable server-side encryption for artifacts
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = {
    Name = "${var.vpc_name}-codepipeline-artifacts"
  }
}
# Generate a random suffix for bucket name to ensure uniqueness
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}
# --- IAM Roles and Policies for CodePipeline, CodeBuild, CodeDeploy ---
# 1. CodePipeline IAM Role
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.vpc_name}-codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.vpc_name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject"
        ],
        Effect = "Allow",
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      },
      {
        Action = [
          "codebuild:StartBuild",
          "codebuild:StopBuild",
          "codebuild:BatchGetBuilds"
        ],
        Effect   = "Allow",
        Resource = "*" # Restrict to specific CodeBuild project ARN for production
      },
      {
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ],
        Effect   = "Allow",
        Resource = "*" # Restrict to specific CodeDeploy app/deployment group ARN for production
      },
      {
        Action = [
          "iam:PassRole"
        ],
        Effect = "Allow",
        Resource = [
          aws_iam_role.codebuild_role.arn, # Pass role to CodeBuild
          aws_iam_role.codedeploy_role.arn # Pass role to CodeDeploy
        ]
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Effect   = "Allow",
        Resource = "*" # Restrict to specific secret ARN for production
      }
    ]
  })
}
# 2. CodeBuild IAM Role
resource "aws_iam_role" "codebuild_role" {
  name = "${var.vpc_name}-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.vpc_name}-codebuild-policy"
  role = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = ["arn:aws:logs:${var.aws_region}:*:log-group:/aws/codebuild/${var.vpc_name}-codebuild-project:*"]
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ],
        Effect = "Allow",
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      }
    ]
  })
}
# 3. CodeDeploy IAM Role
resource "aws_iam_role" "codedeploy_role" {
  name = "${var.vpc_name}-codedeploy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role_policy" "codedeploy_policy" {
  name = "${var.vpc_name}-codedeploy-policy"
  role = aws_iam_role.codedeploy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeInstanceStatus"
        ],
        Effect   = "Allow",
        Resource = "*" # Or restrict to specific ASG/EC2 tags
      },
      {
        Action = [
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLifecycleHooks",
          "autoscaling:DescribeNotificationConfigurations",
          "autoscaling:DescribePolicies",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "autoscaling:SuspendProcesses",
          "autoscaling:ResumeProcesses",
          "autoscaling:UpdateAutoScalingGroup"
        ],
        Effect   = "Allow",
        Resource = "*" # Or restrict to specific ASG ARN
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject" # For S3 deployment types
        ],
        Effect = "Allow",
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      }
    ]
  })
}
# --- CodeDeploy Application and Deployment Group ---
resource "aws_codedeploy_app" "web_app" {
  name = "${var.vpc_name}-codedeploy-app"
}
resource "aws_codedeploy_deployment_group" "web_app" {
  application_name      = aws_codedeploy_app.web_app.name
  deployment_group_name = "${var.vpc_name}-codedeploy-dg"
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "${var.instance_name}-ASG-Instance" # Matching instance tag from launch template
    }
  }
  # For Auto Scaling Group deployments
  autoscaling_groups = [aws_autoscaling_group.web_app.name]
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL" # Recommended for ASG
    deployment_type   = "IN_PLACE"             # Or BLUE_GREEN
  }
  # For traffic control (e.g., during Blue/Green or with_traffic_control)
  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.web_app.name
    }
  }
}
# --- CodeBuild Project ---
resource "aws_codebuild_project" "web_app" {
  name          = "${var.vpc_name}-codebuild-project"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "60" # minutes
  artifacts {
    type = "CODEPIPELINE" # Output artifacts to CodePipeline
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0" # Or other suitable image
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    image_pull_credentials_type = "CODEBUILD"
  }
  source {
    type      = "CODEPIPELINE"  # Input source from CodePipeline
    buildspec = "buildspec.yml" # Your application's buildspec file
  }
  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.vpc_name}-codebuild-project"
      stream_name = "logs"
    }
  }
  tags = {
    Name = "${var.vpc_name}-codebuild"
  }
}
# --- CodePipeline Definition ---
resource "aws_codepipeline" "web_app" {
  name     = "${var.vpc_name}-codepipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
      configuration = {
        Owner  = var.github_repo_owner
        Repo   = var.github_repo_name
        Branch = var.github_repo_branch
        # Important: Token stored in Secrets Manager, referenced by name
        OAuthToken = var.github_token_secret_name
      }
    }
  }
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.web_app.name
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["BuildArtifact"]
      version         = "1"
      configuration = {
        ApplicationName     = aws_codedeploy_app.web_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.web_app.name
      }
    }
  }
  tags = {
    Name = "${var.vpc_name}-codepipeline"
  }
}
