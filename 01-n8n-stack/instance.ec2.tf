resource "aws_instance" "this" {
  ami                         = "ami-0b29c89c15cfb8a6d"
  instance_type               = "t4g.small"
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = false # Desativado para evitar conflito com o EIP
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.role_acesso_ssm.name

  # user_data
  user_data = file("user_data.sh")

  # volume
  root_block_device {
    volume_size = 30
    encrypted   = true
  }

  tags = {
    Name     = var.aws_instance_name
    ambiente = "production"
    # Tags usadas pelo user_data.sh para configurar S3 automaticamente
    typebot_s3_bucket     = aws_s3_bucket.typebot_uploads.id
    typebot_s3_access_key = aws_iam_access_key.typebot_s3.id
    typebot_s3_secret_key = aws_iam_access_key.typebot_s3.secret
  }

  depends_on = [
    aws_s3_bucket.typebot_uploads,
    aws_iam_access_key.typebot_s3
  ]

}
