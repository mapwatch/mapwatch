# I configure the resources for a static website:
# * Hosted from an S3 bucket
# * Accessed from a Cloudflare subdomain
# * Deployed on git-push via a Travis-CI build (see also .travis.yml)
# * Deployed by an AWS IAM user with minimal permissions for just this project
#
# Run me with `terraform apply`.
#
# To use me in a new project, just copy me, and maybe the CI config file too.
# (Terraform supports remote modules, but I don't use them here: I like having
# my TF code version-controlled with its project, and abstraction is harder.)

# Terraform state-tracking and credentials boilerplate
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

locals {
  subdomain  = "mapwatch"
  hostdomain = "erosson.org"
  fulldomain = "${local.subdomain}.${local.hostdomain}"

  # Encrypt the deploy user's secret key in terraform state.
  # Use any keybase user here; the secret key's not needed after provisioning.
  pgp_key = "keybase:erosson"
}

# Configuring a new project with a different domain? You shouldn't need to edit anything beyond this point.

# DNS entry for this project
resource "cloudflare_record" "dns" {
  domain  = "${local.hostdomain}"
  name    = "${local.subdomain}"
  type    = "CNAME"
  value   = "${local.fulldomain}.s3-website-us-east-1.amazonaws.com"
  proxied = true
}

# Deploy to a world-readable bucket
resource "aws_s3_bucket" "web" {
  bucket = "${local.fulldomain}"
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
      "Resource":["arn:aws:s3:::${local.fulldomain}/*"]
    }
  ]
}
POLICY

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

# A newly-created AWS user deploys to S3 on commit.
# Permissions are restricted to this project's S3 bucket.
resource "aws_iam_user" "deploy" {
  name = "deploy@${local.fulldomain}"
}

# https://www.terraform.io/docs/providers/aws/r/iam_access_key.html
# Secret key is written to terraform's state file, encrypted with my secret key.
# Provisioner tells travis about it after creation.
# TODO: delete the secret key from terraform after creation; it's not needed once travis knows about it
#
# from https://www.terraform.io/docs/providers/aws/r/iam_access_key.html :
# > terraform output deploy_access_key
# > terraform output deploy_secret_key | base64 --decode | keybase pgp decrypt
resource "aws_iam_access_key" "deploy" {
  user    = "${aws_iam_user.deploy.name}"
  pgp_key = "${local.pgp_key}"

  provisioner "local-exec" {
    command = <<EOF
set -eu   # quit if I try to use an undefined variable, or after any exit-code-error command
travis env set --private AWS_SECRET_ACCESS_KEY $(echo ${aws_iam_access_key.deploy.encrypted_secret} | base64 --decode | keybase pgp decrypt)
travis env set --public AWS_ACCESS_KEY_ID ${aws_iam_access_key.deploy.id}
travis env set --private CLOUDFLARE_TOKEN $CLOUDFLARE_TOKEN
travis env set --public CLOUDFLARE_EMAIL $CLOUDFLARE_EMAIL
travis env list
EOF
  }
}

resource "aws_iam_user_policy" "deploy" {
  name = "deploy@${local.fulldomain}"
  user = "${aws_iam_user.deploy.name}"

  # minimum-access s3 policy for the deploying user.
  # this helped, though CI might not use s3sync:
  # https://blog.willj.net/2014/04/18/aws-iam-policy-for-allowing-s3cmd-to-sync-to-an-s3-bucket/
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${local.fulldomain}",
                "arn:aws:s3:::${local.fulldomain}/*"
            ]
        }
    ]
}
EOF
}
