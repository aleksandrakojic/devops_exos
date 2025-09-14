
variable "vpc_cidr_block" {
  description = "The CIDR block for the main VPC."
  type        = string
  default     = "10.0.0.0/16" # A common, safe default
}
variable "vpc_name" {
  description = "Name tag for the main VPC."
  type        = string
  default     = "MyWebAppVPC"
}
variable "aws_region" {
  description = "The AWS region where resources will be deployed."
  type        = string
  default     = "us-east-1" # Set your preferred region here!
}
variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks for public subnets (e.g., for ALB, Bastion Hosts)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"] # Two subnets for high availability
}
variable "availability_zones" {
  description = "A list of Availability Zones to deploy resources into. Must match length of public_subnet_cidrs."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"] # Ensure these are valid for your chosen region
}
variable "instance_ami" {
  description = "The AMI ID for the EC2 instance. Use a data source for production!"
  type        = string
  # IMPORTANT: This AMI is for us-east-1 (Amazon Linux 2023).
  # Always verify AMIs for your region and desired OS.
  default     = "ami-0be726487192f153f" # Example: Amazon Linux 2023 AMI
}
variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t3.micro" # Good for free tier or small tests
}
variable "instance_key_name" {
  description = "The name of the EC2 Key Pair for SSH access."
  type        = string
  # !!! IMPORTANT: You MUST have this key pair already created in your AWS region.
  # Otherwise, you won't be able to SSH into your instance.
  # E.g., 'my-ssh-key'
}
variable "instance_name" {
  description = "Name tag for the EC2 instance."
  type        = string
  default     = "MyWebAppServer"
}
variable "app_port" {
  description = "The port your application listens on within the EC2 instances."
  type        = number
  default     = 80 # Our Apache server listens on 80
}
variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 1
}
variable "asg_desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group."
  type        = number
  default     = 2 # We want at least two instances for high availability
}
variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 3
}
variable "alb_name_prefix" {
  description = "A prefix for the ALB name."
  type        = string
  default     = "my-web-app-alb"
}
variable "domain_name" {
  description = "The root domain name (e.g., example.com) that will be managed by Route 53."
  type        = string
  # !!! IMPORTANT: Replace 'example.com' with your actual domain!
  default     = "yourdomain.com"
}
variable "subdomain_name" {
  description = "The subdomain for your web application (e.g., www)."
  type        = string
  default     = "www"
}
variable "github_repo_owner" {
  description = "The owner (username or organization) of your GitHub repository."
  type        = string
  default     = "adityar947" # Replace with your GitHub username/org!
}
variable "github_repo_name" {
  description = "The name of your GitHub repository containing the application code."
  type        = string
  # IMPORTANT: Replace with the actual name of your application repo (e.g., angular-app-aws-cicd)
  default     = "angular-app-aws-cicd"
}
variable "github_repo_branch" {
  description = "The branch of your GitHub repository to monitor for changes."
  type        = string
  default     = "main"
}
variable "github_token_secret_name" {
  description = "The name of the AWS Secrets Manager secret storing your GitHub Personal Access Token."
  type        = string
  # !!! YOU MUST CREATE THIS SECRET MANUALLY IN SECRETS MANAGER FIRST !!!
  # Name it exactly 'github-token' or whatever you set here.
  # The secret value should be your GitHub PAT.
  default     = "github-token"
}