## Concourse CI

[![Build Status](https://travis-ci.com/telia-oss/terraform-aws-concourse.svg?branch=master)](https://travis-ci.com/telia-oss/terraform-aws-concourse)

A Terraform module for deploying Concourse CI.

## Prerequisites

1. Use [Packer](https://www.packer.io/) to create an AMI with Concourse and [lifecycled](https://github.com/buildkite/lifecycled) installed:

```bash
packer validate template.json

packer build \
  -var="source_ami=<amazon-linux-2>" \
  -var="concourse_version=v3.14.1" \
  template.json
```

2. Generate key pairs for Concourse:

```bash
# Create folder
mkdir -p keys

ssh-keygen -t rsa -f ./keys/tsa_host_key -N ''
ssh-keygen -t rsa -f ./keys/worker_key -N ''
ssh-keygen -t rsa -f ./keys/session_signing_key -N ''

# Authorized workers
cp ./keys/worker_key.pub ./keys/authorized_worker_keys
```


NOTE: The `source_ami` for packer must be an Amazon Linux 2 AMI since the launch configuration uses systemd.

### Required for HTTPS

Route53 hosted zone, domain and ACM certificate.

### Required for Github authentication

Github Oauth application, with an encrypted password:

```bash
aws kms encrypt \
  --key-id <aws-kms-key-id> \
  --plaintext <github-client-secret> \
  --output text \
  --query CiphertextBlob \
  --profile default
```

## Usage

See example.

## Concourse usage

To create a new team in Concourse, an admin first logs into the `main` team:

```bash
fly --target admin login --team-name main --concourse-url https://ci.example.com
## Same command with short flags:
fly -t admin login -n main -c https://ci.example.com
```

Set up a new team:

```bash
fly -t admin set-team -n demo-team \
    --github-auth-client-id <client> \
    --github-auth-client-secret <secret> \
    --github-auth-team TeliaSoneraNorge/demo-team
```

And then we can log into the new team:

```bash
fly --target demo login --team-name demo-team --concourse-url https://ci.example.com
```
