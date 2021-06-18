include {
  path = find_in_parent_folders()
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-s3-bucket?ref=v2.4.0"
}

locals {}

dependencies {
  paths = ["../../eks-vpc"]
}

inputs = {
  bucket                  = "tink3-sandbox-infra-testing-awsproton"
  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  force_destroy           = true
  versioning = {
    enabled = true
  }
}
