terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  default     = ""  # Or set via environment variable
}

variable "ssh_key_fingerprint" {
  description = "Fingerprint of the SSH key added to DigitalOcean"
  type        = string
}

resource "digitalocean_ssh_key" "default" {
  name       = "my_ssh_key"
  fingerprint = var.ssh_key_fingerprint
}

resource "digitalocean_droplet" "node_app" {
  name   = "nodejs-app"
  region = "nyc3"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-20-04-x64"
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]
}

output "droplet_ip" {
  value = digitalocean_droplet.node_app.ipv4_address
}