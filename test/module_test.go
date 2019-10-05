package module_test

import (
	"flag"
	"fmt"
	"strings"
	"testing"

	asg "github.com/telia-oss/terraform-aws-asg/v3/test"
	concourse "github.com/telia-oss/terraform-aws-concourse/v3/test"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/packer"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

var amiID = flag.String("ami-id", "", "Concourse AMI ID.")

func TestModule(t *testing.T) {
	tests := []struct {
		description string
		directory   string
		name        string
		password    string
		region      string
		expected    concourse.Expectations
	}{
		{
			description: "basic example",
			directory:   "../examples/basic",
			name:        fmt.Sprintf("concourse-basic-test-%s", random.UniqueId()),
			password:    random.UniqueId(),
			region:      "eu-west-1",
			expected: concourse.Expectations{
				Version:       "5.6.0",
				WorkerVersion: "2.2",
				ATCAutoscaling: asg.Expectations{
					MinSize:         1,
					MaxSize:         2,
					DesiredCapacity: 1,
					InstanceType:    "t3.small",
					InstanceTags: map[string]string{
						"terraform":   "True",
						"environment": "dev",
					},
					UserData: []string{
						`Environment="CONCOURSE_GITHUB_CLIENT_ID=sm:///concourse-deployment/github-oauth-client-id"`,
						`Environment="CONCOURSE_GITHUB_CLIENT_SECRET=sm:///concourse-deployment/github-oauth-client-secret"`,
						`Environment="CONCOURSE_MAIN_TEAM_GITHUB_USER=itsdalmo"`,
						`Environment="CONCOURSE_MAIN_TEAM_GITHUB_TEAM=telia-oss:concourse-owners"`,
						`Environment="CONCOURSE_MAIN_TEAM_LOCAL_USER=admin"`,
						`Environment="CONCOURSE_POSTGRES_PORT=5439"`,
						`Environment="CONCOURSE_POSTGRES_USER=superuser"`,
						`Environment="CONCOURSE_POSTGRES_PASSWORD=dolphins"`,
						`Environment="CONCOURSE_POSTGRES_DATABASE=main"`,
						`Environment="CONCOURSE_LOG_LEVEL=info"`,
						`Environment="CONCOURSE_TSA_LOG_LEVEL=info"`,
						`Environment="CONCOURSE_TSA_HOST_KEY=/concourse/keys/web/tsa_host_key"`,
						`Environment="CONCOURSE_TSA_AUTHORIZED_KEYS=/concourse/keys/web/authorized_worker_keys"`,
						`Environment="CONCOURSE_SESSION_SIGNING_KEY=/concourse/keys/web/session_signing_key"`,
						`Environment="CONCOURSE_ENCRYPTION_KEY="`,
						`Environment="CONCOURSE_OLD_ENCRYPTION_KEY="`,
						`Environment="CONCOURSE_AWS_SECRETSMANAGER_REGION=eu-west-1"`,
					},
					IsGzippedUserData: true,
				},
				WorkerAutoscaling: asg.Expectations{
					MinSize:         1,
					MaxSize:         3,
					DesiredCapacity: 1,
					InstanceType:    "t3.large",
					InstanceTags: map[string]string{
						"terraform":   "True",
						"environment": "dev",
					},
					UserData: []string{
						`Environment="CONCOURSE_TEAM="`,
						`Environment="CONCOURSE_BIND_IP=0.0.0.0"`,
						`Environment="CONCOURSE_LOG_LEVEL=info"`,
						`Environment="CONCOURSE_WORK_DIR=/concourse"`,
						`Environment="CONCOURSE_BAGGAGECLAIM_BIND_IP=0.0.0.0"`,
						`Environment="CONCOURSE_BAGGAGECLAIM_LOG_LEVEL=info"`,
						`Environment="CONCOURSE_TSA_PUBLIC_KEY=/concourse/keys/worker/tsa_host_key.pub"`,
						`Environment="CONCOURSE_TSA_WORKER_PRIVATE_KEY=/concourse/keys/worker/worker_key"`,
						`Environment="CONCOURSE_REBALANCE_INTERVAL=30m"`,
						`ExecStartPre=/bin/bash -c "/bin/systemctl set-environment CONCOURSE_NAME=$(curl -L http://169.254.169.254/latest/meta-data/instance-id)"`,
						`ExecStart=/usr/local/concourse/bin/concourse worker`,
						`ExecStop=/usr/local/concourse/bin/concourse retire-worker`,
						`ExecStop=/bin/bash -c "while pgrep concourse >> /dev/null; do echo draining worker... && sleep 5; done; echo done draining!"`,
					},
					IsGzippedUserData: true,
				},
			},
		},
	}

	for _, tc := range tests {
		tc := tc // Source: https://gist.github.com/posener/92a55c4cd441fc5e5e85f27bca008721
		t.Run(tc.description, func(t *testing.T) {
			t.Parallel()

			amiID := *amiID
			if amiID == "" {
				amiID = packer.BuildArtifact(t, &packer.Options{
					Template: "../packer/template.json",

					Vars: map[string]string{
						"template_version": "dev",
					},

					Only: "amazon-ebs",
				})
				defer aws.DeleteAmiAndAllSnapshots(t, tc.region, amiID)
			}

			options := &terraform.Options{
				TerraformDir: tc.directory,

				Vars: map[string]interface{}{
					// aws_db_subnet_group requires a lowercase name.
					"name_prefix":              strings.ToLower(tc.name),
					"concourse_admin_password": tc.password,
					"packer_ami":               amiID,
					"region":                   tc.region,
				},

				EnvVars: map[string]string{
					"AWS_DEFAULT_REGION": tc.region,
				},
			}

			defer terraform.Destroy(t, options)
			terraform.InitAndApply(t, options)

			concourse.RunTestSuite(t,
				terraform.Output(t, options, "endpoint"),
				terraform.Output(t, options, "atc_asg_id"),
				terraform.Output(t, options, "worker_asg_id"),
				"admin",
				tc.password,
				tc.region,
				tc.expected,
			)
		})
	}
}
