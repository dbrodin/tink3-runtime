# AWS Proton Sample Microservices Using Amazon ECS and AWS Fargate

This directory contains a sample AWS Proton Environment and Service templates for a set of Amazon ECS based microservices using service discovery running on AWS Fargate, as well as sample specs for creating Proton Environments and Services using the templates. All resources deployed are tagged.

The environment template deploys:
- Re-use existing VPC from input
- an ECS Cluster
- a private namespace for service discovery

The service templates contains all the resources required to create a public ECS Fargate service behind a load balancer and a private ECS Fargate service in that environment. It also provides sample specs for creating Proton Environments and Services using the templates.

Developers provisioning their services can configure the following properties through their service spec:

- Fargate CPU size
- Fargate memory size
- Number of running containers
- Choose private or public subnets to run the loadbalanced service or the private service, accessed via service discovery
- Service name to register and use for service discovery

# Registering and deploying these templates

You can register and deploy these templates by using the AWS Proton console. To do this, you will need to compress the templates using the instructions below, upload them to an S3 bucket, and use the Proton console to register and test them. If you prefer to use the Command Line Interface, follow the instructions below:

## Prerequisites

First, make sure you have the AWS CLI installed, and configured.
Assume the role in tink3-sandbox

## Register an Environment Template

Create a version which contains the contents of the environment template. Compress the sample template files and register the version:

Set variables
```bash
ENV_TEMPLATE_NAME="infra-testing-proton-2"
PROTON_MAJOR_VERSION="1"
PROTON_MINOR_VERSION="3"
BUCKET_NAME="bucket=tink3-sandbox-infra-testing-awsproton"
```

```bash
ENV_TEMPLATE_TAR="env-reuse-vpc-template.tar.gz"
tar -zcvf ${ENV_TEMPLATE_TAR} environment/

aws s3 cp ${ENV_TEMPLATE_TAR} s3://${BUCKET_NAME}/environments/templates/${ENV_TEMPLATE_TAR}

rm ${ENV_TEMPLATE_TAR}

aws proton \
  create-environment-template-version \
  --template-name "${ENV_TEMPLATE_NAME}" \
  --description "Infra testing proton version ${PROTON_MAJOR_VERSION}.${PROTON_MINOR_VERSION}" \
  --source s3="{bucket=${BUCKET_NAME},key=environments/templates/env-reuse-vpc-template.tar.gz}"
```

Wait for the environment template version to be successfully registered. Use this command to verify status

```bash
aws proton get-environment-template-version \
  --template-name "${ENV_TEMPLATE_NAME}" \
  --major-version "${PROTON_MAJOR_VERSION}" \
  --minor-version "${PROTON_MINOR_VERSION}"
```

You can now publish the environment template version, making it available for users in your AWS account to create Proton environments.

```bash
aws proton \
  update-environment-template-version \
  --template-name "${ENV_TEMPLATE_NAME}" \
  --major-version "${PROTON_MAJOR_VERSION}" \
  --minor-version "${PROTON_MINOR_VERSION}" \
  --status "PUBLISHED"
```

## Register the Service Templates

Register the sample services templates, which contains all the resources required to provision an ECS Fargate services behind a load balancer, the private services as well as a continuous delivery pipeline using AWS CodePipeline for each.

### First, create the Public service template.

```bash
aws proton \
  create-service-template \
  --template-name "infra-testing-public-fargate-1" \
  --display-name "PublicLoadbalancedFargateService" \
  --description "Fargate ECS Service with a public Application Load Balancer"
```

Now create a version which contains the contents of the sample service template. Compress the sample template files and register the version:

```bash
PUBLIC_TEMPLATE_TAR="public-svc-template.tar.gz"
tar -zcvf ${PUBLIC_TEMPLATE_TAR} service/loadbalanced-public-svc/

aws s3 cp ${PUBLIC_TEMPLATE_TAR} s3://${BUCKET_NAME}/services/${PUBLIC_TEMPLATE_TAR}

rm ${PUBLIC_TEMPLATE_TAR}

aws proton \
  create-service-template-version \
  --template-name "infra-testing-public-fargate-1" \
  --description "Version 1" \
  --source s3="{bucket=proton-cli-templates-${account_id},key=svc-private-template.tar.gz}" \
  --compatible-environment-templates '[{"templateName":"aws-proton-fargate-microservices","majorVersion":"1"}]'
```




## TODO: FIX the rest of the examples if needed..

Wait for the service template version to be successfully registered. Use this command to verify status

```
aws proton get-service-template-version \
  --region eu-west-1 \
  --template-name "lb-public-fargate-svc" \
  --major-version "1" \
  --minor-version "0"
```

You can now publish the Public service template version, making it available for users in your AWS account to create Proton services.

```
aws proton \
  --region eu-west-1 \
  update-service-template-version \
  --name "lb-public-fargate-svc" \
  --major-version "1" \
  --minor-version "0" \
  --status "PUBLISHED"
```

### Second, create the Private service template.

## Deploy An Environment and Services

With the registered and published environment and service templates, you can now instantiate a Proton environment and service from the templates.

First, deploy a Proton environment. This command reads your environment spec at `specs/env-spec.yaml`, merges it with the environment template created above, and deploys the resources in a CloudFormation stack in your AWS account using the Proton service role.

**TODO: fix this so that it works**
```bash
aws proton create-environment \
  --region eu-west-1 \
  --name "Beta" \
  --template-name aws-proton-fargate-microservices \
  --template-major-version 1 \
  --proton-service-role-arn arn:aws:iam::${account_id}:role/ProtonServiceRole \
  --spec file://specs/env-spec.yaml
```

Wait for the environment to successfully deploy. Use this command to verify deployment status:

```
aws proton get-environment \
  --region eu-west-1 \
  --name "Beta"
```

Then, create a Public Proton service and deploy it into your Proton environment.  This command reads your service spec at `specs/svc-public-spec.yaml`, merges it with the service template created above, and deploys the resources in CloudFormation stacks in your AWS account using the Proton service role.  The service will provision a load-balanced ECS service running on Fargate and a CodePipeline pipeline to deploy your application code.

Fill in your CodeStar Connections connection ID and your source code repository details in this command.

```bash
SVC_NAME="arneanka"
REPO_CONNECTION_ARN="arn:aws:codestar-connections:eu-west-1:649414960431:connection/6c521ae7-eec2-42d9-8f82-1c2fc5ab2b4e"
REPO_ID="tink-ab/arneanka"
MAJOR_VERSION="1"
PUB_SVC_TEMPLATE_NAME="infra-testing-public-fargate-1"
aws proton create-service \
  --name "${SVC_NAME}" \
  --repository-connection-arn ${REPO_CONNECTION_ARN} \
  --repository-id "${REPO_ID}" \
  --branch "master" \
  --template-major-version ${MAJOR_VERSION} \
  --template-name ${PUB_SVC_TEMPLATE_NAME} \
  --spec file://specs/svc-public-spec.yaml
```

Wait for the service to successfully deploy. Use this command to verify deployment status

```
aws proton get-service --name "${SVC_NAME}"
```
