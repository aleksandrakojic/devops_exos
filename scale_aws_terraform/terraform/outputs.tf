output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}
output "website_url" {
  description = "The public URL of your web application via custom domain."
  value       = "http://${var.subdomain_name}.${var.domain_name}"
}
output "route53_name_servers" {
  description = "The Name Servers for your Route 53 Hosted Zone. Update your domain registrar with these if this zone was newly created."
  value       = aws_route53_zone.main_public.name_servers
}