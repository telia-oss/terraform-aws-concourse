## Concourse CI

[![Build Status](https://travis-ci.com/telia-oss/terraform-aws-concourse.svg?branch=master)](https://travis-ci.com/telia-oss/terraform-aws-concourse)

A Terraform module for deploying Concourse CI.

## Prerequisites

1. Use [Packer](https://www.packer.io/) to create an AMI with Concourse and [lifecycled](https://github.com/buildkite/lifecycled) installed:

```bash
packer validate template.json

packer build \
  -var="source_ami=<amazon-linux-2>" \
  -var="concourse_version=v4.2.1" \
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


3. Required (when using the root module) for the [Github Lambda](https://github.com/telia-oss/concourse-github-lambda)

Create two Github Apps and add the [four required secrets](https://github.com/telia-oss/concourse-github-lambda#secrets) for the Github Lambda under the `/concourse-github-lambda/` path, e.g.:

```bash
aws secretsmanager create-secret \
  --name /concourse-github-lambda/token-service/integration-id \
  --secret-string "13024" \
  --region eu-west-1
```

## Usage

See examples. The root module is intended to provide a production grade deployment of Concourse and is therefore very opinionated; check out the [modular](examples/modular) example if you want
more flexibility. If you want to learn more about how to use Concourse, check out the [official documentation](https://concourse-ci.org).

## Examples

* [Simple Example](examples/default/example.tf)
* [Modular Example](examples/modular/example.tf)

## Related projects

- [concourse-images](https://github.com/telia-oss/concourse-images): A collection of docker images for use in Concourse tasks.
- [concourse-tasks](https://github.com/telia-oss/concourse-tasks): A very small collection of Concourse tasks :)
- [concourse-sts-lambda](https://github.com/telia-oss/concourse-sts-lambda): Lambda for managing temporary AWS credentials stored in Secrets Manager.
- [concourse-github-lambda](https://github.com/telia-oss/concourse-github-lambda): Lambda for managing Github deploy keys.

## Authors

Currently maintained by [these contributors](../../graphs/contributors).

## License

MIT License. See [LICENSE](LICENSE) for full details.
