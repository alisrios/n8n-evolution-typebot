data "aws_route53_zone" "primary" {
  name = "alisriosti.com.br"
}

resource "aws_route53_record" "n8n" {
  zone_id = data.aws_route53_zone.primary.zone_id # Substitua pelo ID correto da sua zona
  name    = "n8n.alisriosti.com.br"
  type    = "A"
  ttl     = 300
  records = [aws_eip.this.public_ip]
}

resource "aws_route53_record" "evolution" {
  zone_id = data.aws_route53_zone.primary.zone_id # Substitua pelo ID correto da sua zona
  name    = "evolution-api.alisriosti.com.br"
  type    = "A"
  ttl     = 300
  records = [aws_eip.this.public_ip]
}

resource "aws_route53_record" "typebot" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "typebot.alisriosti.com.br"
  type    = "A"
  ttl     = 300
  records = [aws_eip.this.public_ip]
}

resource "aws_route53_record" "typebot_viewer" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "typebot-viewer.alisriosti.com.br"
  type    = "A"
  ttl     = 300
  records = [aws_eip.this.public_ip]
}