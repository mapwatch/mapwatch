provider "aws" {
  region = "us-east-1"
}
provider "cloudflare" {}

terraform {
  backend "s3" {
    bucket = "terraform-backend.erosson.org"
    key    = "mapwatch"
    region = "us-east-1"
  }
}

resource "cloudflare_record" "mapwatch_erosson_org" {
  domain  = "erosson.org"
  name    = "mapwatch"
  type    = "CNAME"
  value   = "mapwatch.erosson.org.s3-website-us-east-1.amazonaws.com"
  proxied = true
}

resource "aws_s3_bucket" "mapwatch_erosson_org" {
  bucket = "mapwatch.erosson.org"
  acl    = "public-read"

  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::mapwatch.erosson.org/*"]
    }
  ]
}
POLICY

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}
