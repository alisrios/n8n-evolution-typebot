output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

output "instance_id" {
  description = "ID da instancia EC2"
  value       = aws_instance.this.id
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

output "typebot_s3_bucket_name" {
  description = "Nome do bucket S3 para uploads do Typebot"
  value       = aws_s3_bucket.typebot_uploads.id
}

output "typebot_s3_bucket_endpoint" {
  description = "Endpoint do bucket S3"
  value       = "https://${aws_s3_bucket.typebot_uploads.bucket_regional_domain_name}"
}

output "typebot_s3_access_key_id" {
  description = "Access Key ID para o Typebot"
  value       = aws_iam_access_key.typebot_s3.id
  sensitive = true
}

output "typebot_s3_secret_access_key" {
  description = "Secret Access Key para o Typebot"
  value       = aws_iam_access_key.typebot_s3.secret
  sensitive = true
}