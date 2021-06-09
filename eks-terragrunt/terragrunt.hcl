## Define remote state and config files

terragrunt_version_constraint = ">= 0.23"
terraform_version_constraint  = "= 0.14.4"

locals {
  config_file = yamldecode(file("config.yaml"))

  tf_state_config = local.config_file["tf-state"]
  state_bucket    = local.tf_state_config["tf_remote_state_bucket"]
  state_lock      = local.tf_state_config["tf_remote_dynamodb_lock"]

  region = local.config_file["region"]
}

inputs = {
  region = local.region
}

remote_state {
  backend = "s3"

  config = {
    bucket         = local.state_bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = local.state_lock
  }

  generate = {
    path      = "terraform_backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.region}"
    }
  EOF
}
