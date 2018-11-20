## Concourse CI

[![Build Status](https://travis-ci.com/telia-oss/terraform-aws-concourse.svg?branch=master)](https://travis-ci.com/telia-oss/terraform-aws-concourse)

A Terraform module for deploying Concourse CI.

## Prerequisites

1. Use [Packer](https://www.packer.io/) to create an AMI with Concourse (and related tooling installed) installed:

```bash
# From the project root, using make:
make ami
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

See example. If you want to learn more about how to use Concourse,
check out the [official documentation](https://concourse-ci.org).

## Related projects

- [concourse-images](https://github.com/telia-oss/concourse-images): A collection of docker images for use in Concourse tasks.
- [concourse-tasks](https://github.com/telia-oss/concourse-tasks): A very small collection of Concourse tasks :)
- [concourse-sts-lambda](https://github.com/telia-oss/concourse-sts-lambda): Lambda for managing temporary AWS credentials stored in Secrets Manager.
- [concourse-github-lambda](https://github.com/telia-oss/concourse-github-lambda): Lambda for managing Github deploy keys.
