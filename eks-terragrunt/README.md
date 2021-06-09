# Setup EKS cluster with dependencies with Terragrunt

This is designed to support running `run-all` with the help of the dependecy configs in each of the folders.

from the root:
`terragrunt run-all apply`

You can also to into each of the directories and apply
`cd eks-terragrunt/eks-vpc/`
`terragrunt plan/apply`

# Config file

The **config.yaml** file will contain all configurations for the resources.
You can define namespaces that should be created etc.

# Charts and Kubernetes deploy

You can deploy helm charts with the **k8s-charts**. This will help bootstrap the cluster.

Could also implement feature to deploy charts from local folder in this repo.

The kubectl terraform provider is used and that can help running kubectl commands

Terragrunt has some nice feature such as
* run_cmd(shell.sh) used in the terragrunt.hcl file
* before_hook
* after_hook

```hcl
# Examples with run_cmd()
remote_state {
  backend = "s3"
  config = {
    bucket         = run_cmd("./get_names.sh", "bucket")
    dynamodb_table = run_cmd("./get_names.sh", "dynamodb")
  }
}

# Examples running hooks
terraform {
  before_hook "before_hook" {
    commands     = ["apply", "plan"]
    execute      = ["echo", "Running Terraform"]
  }

  after_hook "after_hook" {
    commands     = ["apply", "plan"]
    execute      = ["echo", "Finished running Terraform"]
    run_on_error = true
  }
}
```
