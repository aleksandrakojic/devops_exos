resource "digitalocean_droplet" "web" {
  name   = "terraform-droplet"
  region = "nyc3"  # or your preferred region
  size   = "s-1vcpu-1gb"  # Basic size
  image  = "ubuntu-20-04-x64"  # Ubuntu image
  ssh_keys = [<SSH_KEY_ID>]  # Optional: specify your SSH key ID for access
}

output "droplet_ip" {
  value = digitalocean_droplet.web.ipv4_address
}