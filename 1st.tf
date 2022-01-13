# Terraform Setting
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# AWS Provider
provider "aws" {
  region = "ap-northeast-1"
  access_key = var.accessKey
  secret_key = var.secretKey
}

# ACM Certificate
resource "aws_acm_certificate" "ac0" {
  domain_name       = var.domain
  subject_alternative_names = [var.subdomain]
  validation_method = "DNS"

  lifecycle { prevent_destroy = true }
}

# ACM Certificate Validation
resource "aws_acm_certificate_validation" "acv0" {
  certificate_arn         = aws_acm_certificate.ac0.arn
  validation_record_fqdns = [for record in aws_route53_record.httpsRec0 : record.fqdn]
}

# SES Domain Identity
#resource "aws_ses_domain_identity" "sesDomain0" {
#  domain = var.domain
#}

# SES Domain Mail From
#resource "aws_ses_domain_mail_from" "sesDomainMailFrom0" {
#  domain           = aws_ses_domain_identity.sesDomain0.domain
#  mail_from_domain = "bounce.${aws_ses_domain_identity.example.domain}"
#}

# SNS Topic
#resource "aws_sns_topic" "snsTopic0" {
#  name = "sesBounce"
#}

#resource "aws_sns_topic" "snsTopic1" {
#  name = "sesComplaint"
#}

#resource "aws_sns_topic" "snsTopic2" {
#  name = "sesDelivery"
#}

# SES Identity Notification Topic
#resource "aws_ses_identity_notification_topic" "sesTopic0" {
#  topic_arn                = aws_sns_topic.snsTopic0.arn
#  notification_type        = "Bounce"
#  identity                 = aws_ses_domain_identity.sesDomain0.domain
#  include_original_headers = true
#}

#resource "aws_ses_identity_notification_topic" "sesTopic1" {
#  topic_arn                = aws_sns_topic.snsTopic1.arn
#  notification_type        = "Complaint"
#  identity                 = aws_ses_domain_identity.sesDomain0.domain
#  include_original_headers = true
#}

#resource "aws_ses_identity_notification_topic" "sesTopic2" {
#  topic_arn                = aws_sns_topic.snsTopic2.arn
#  notification_type        = "Delivery"
#  identity                 = aws_ses_domain_identity.sesDomain0.domain
#  include_original_headers = true
#}

# SNS Topic Subscription
#resource "aws_sns_topic_subscription" "snsTopicSub0" {
#  topic_arn = aws_sns_topic.snsTopic0.arn
#  protocol  = "email"
#  endpoint  = var.receiverMail
#}

#resource "aws_sns_topic_subscription" "snsTopicSub1" {
#  topic_arn = aws_sns_topic.snsTopic1.arn
#  protocol  = "email"
#  endpoint  = var.receiverMail
#}

#resource "aws_sns_topic_subscription" "snsTopicSub2" {
#  topic_arn = aws_sns_topic.snsTopic2.arn
#  protocol  = "email"
#  endpoint  = var.receiverMail
#}

# SES Email Identity
#resource "aws_ses_email_identity" "sesEmail0" {
#  email = var.receiverMail
#}

# SES Domain DKIM
#resource "aws_ses_domain_dkim" "sesDomainDKIM0" {
#  domain = aws_ses_domain_identity.sesDomain0.domain
#}

# Route53 Zone
resource "aws_route53_zone" "zone0" {
  name = var.domain
}

resource "aws_route53_record" "httpsRec0" {
  for_each = {
    for dvo in aws_acm_certificate.ac0.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.zone0.zone_id
}

# Route53 Record
#resource "aws_route53_record" "sesTXTRec0" {
#  zone_id = aws_route53_zone.zone0.zone_id
#  name    = "_amazonses.${var.domain}"
#  type    = "TXT"
#  ttl     = "300"
#  records = [aws_ses_domain_identity.sesDomain0.verification_token]
#}

#resource "aws_route53_record" "sesDKIMRec0" {
#  count   = 3
#  zone_id = aws_route53_zone.zone0.zone_id
#  name    = "${element(aws_ses_domain_dkim.sesDomainDKIM0.dkim_tokens, count.index)}._domainkey"
#  type    = "CNAME"
#  ttl     = "300"
#  records = ["${element(aws_ses_domain_dkim.sesDomainDKIM0.dkim_tokens, count.index)}.dkim.amazonses.com"]
#}

#resource "aws_route53_record" "sesMXRec0" {
#   zone_id = aws_route53_zone.zone0.zone_id
#   name = var.domain
#   type = "MX"
#   ttl = "300"
#   records = ["10 inbound-smtp.us-east-1.amazonaws.com"]
#}

# S3 Bucket
resource "aws_s3_bucket" "s3b0" {
  bucket = var.s3bucket
}

# ECR
resource "aws_ecr_repository" "ecr0" {
  name                 = "web"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "ecr1" {
  name                 = "app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Private Key
resource "tls_private_key" "pk0" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Key Pair
resource "aws_key_pair" "kp0" {
  key_name   = var.keyPair
  public_key = tls_private_key.pk0.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.pk0.private_key_pem}' > ./${var.keyPair}.pem"
  }
}
