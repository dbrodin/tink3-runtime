# Tink3 Runtime

This repo is for code related to the runtime of the tink3 project

# EKS get access to running cluster:

## IAM kubectl access

IAM access for teams are defined here:
in the eks-terragrunt/config.yaml file:
```yaml
  map_roles:
  - rolearn: "arn:aws:iam::649414960431:role/TinkInfrastructureOncaller"
    username: TinkInfrastructureOncaller
    groups:
    - "system:masters"
```
## Get the EKS config to run kubectl commands

You need `aws cli`, `assume-aws-role` and your role in the **map_roles** from above.

Use `assume-aws-role` to assume the `tink3-sandbox` role

To get the kube config to run kubectl commands to the EKS cluster

Run: `aws eks update-kubeconfig --name infra-testing-cluster-1`
