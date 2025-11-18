# Bucket S3 para uploads do Typebot
resource "aws_s3_bucket" "typebot_uploads" {
  bucket        = "typebot-uploads-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name        = "Typebot Uploads"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Configuração de versionamento
resource "aws_s3_bucket_versioning" "typebot_uploads" {
  bucket = aws_s3_bucket.typebot_uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Configuração de CORS para permitir uploads do Typebot
resource "aws_s3_bucket_cors_configuration" "typebot_uploads" {
  bucket = aws_s3_bucket.typebot_uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = [
      "https://typebot.alisriosti.com.br",
      "https://typebot-viewer.alisriosti.com.br",
      "https://typebot2.alisriosti.com.br",
      "https://typebot-viewer2.alisriosti.com.br",
      "https://*.alisriosti.com.br"
    ]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Política de acesso público para leitura (apenas GET)
resource "aws_s3_bucket_public_access_block" "typebot_uploads" {
  bucket = aws_s3_bucket.typebot_uploads.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Política do bucket para permitir leitura pública
resource "aws_s3_bucket_policy" "typebot_uploads" {
  bucket = aws_s3_bucket.typebot_uploads.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.typebot_uploads.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.typebot_uploads]
}

# IAM User para o Typebot acessar o S3
resource "aws_iam_user" "typebot_s3" {
  name = "typebot-s3-user"

  tags = {
    Name        = "Typebot S3 User"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Política IAM para o usuário do Typebot
resource "aws_iam_user_policy" "typebot_s3" {
  name = "typebot-s3-access"
  user = aws_iam_user.typebot_s3.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.typebot_uploads.arn,
          "${aws_s3_bucket.typebot_uploads.arn}/*"
        ]
      }
    ]
  })
}

# Access Key para o usuário
resource "aws_iam_access_key" "typebot_s3" {
  user = aws_iam_user.typebot_s3.name
}

# Data source para obter o account ID
data "aws_caller_identity" "current" {}
