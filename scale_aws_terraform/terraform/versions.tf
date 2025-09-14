terraform {
  backend "s3" {
    bucket         = "your-unique-terraform-state-bucket-name" # Must be globally unique!
    key            = "my-web-app/terraform.tfstate" # Path to your state file
    region         = "us-east-1" # Your deployment region
    dynamodb_table = "terraform-state-lock-table" # A pre-created DynamoDB table for locking
    encrypt        = true # Always encrypt your state!
  }
}