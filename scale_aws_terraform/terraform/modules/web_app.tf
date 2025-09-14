module "my_network" {
  source = "./modules/vpc" # Local module source
  # ... pass variables ...
}

module "my_web_app_stack" {
  source        = "./modules/web_app_asg" # Local module source
  vpc_id        = module.my_network.vpc_id # Pass outputs from one module to another!
  public_subnets = module.my_network.public_subnet_ids
  # ... pass other variables ...
}