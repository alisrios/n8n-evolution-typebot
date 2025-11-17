output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

output "instance_ip" {
  description = "Ip da instancia ec2-n8n"
  value       = aws_eip.this.public_ip
}

output "route53_n8n" {
  description = "DNS do n8n"
  value       = aws_route53_record.n8n.name
}

output "route53_evolution" {
  description = "DNS do Evolution API"
  value       = aws_route53_record.evolution.name
}

output "route53_typebot" {
  description = "DNS do Typebot Builder"
  value       = aws_route53_record.typebot.name
}

output "route53_typebot_viewer" {
  description = "DNS do Typebot Viewer"
  value       = aws_route53_record.typebot_viewer.name
}