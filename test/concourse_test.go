package concourse_test

import (
	"flag"
	"fmt"
	"io/ioutil"
	"strings"
	"testing"

	asg "github.com/telia-oss/terraform-aws-asg/test"
	concourse "github.com/telia-oss/terraform-aws-concourse/test"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/packer"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

var amiID = flag.String("ami-id", "", "Concourse AMI ID.")

func TestDefaultExample(t *testing.T) {
	tests := []struct {
		description string
		directory   string
		name        string
		region      string
		expected    concourse.Expectations
	}{
		{
			description: "basic example",
			directory:   "../examples/basic",
			name:        fmt.Sprintf("concourse-basic-test-%s", random.UniqueId()),
			region:      "eu-west-1",
			expected: concourse.Expectations{
				ATCAutoscaling: asg.Expectations{
					MinSize:         1,
					MaxSize:         2,
					DesiredCapacity: 1,
					InstanceType:    "t3.small",
					InstanceTags: map[string]string{
						"terraform":   "True",
						"environment": "dev",
					},
					UserData: readGoldenFile(t, "testdata/atc-cloud-config.golden.yml"),
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
					UserData: readGoldenFile(t, "testdata/worker-cloud-config.golden.yml"),
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
					"name_prefix": strings.ToLower(tc.name),
					"packer_ami":  amiID,
					"region":      tc.region,
				},

				EnvVars: map[string]string{
					"AWS_DEFAULT_REGION": tc.region,
				},
			}

			defer terraform.Destroy(t, options)
			terraform.InitAndApply(t, options)

			concourse.RunTestSuite(t,
				terraform.Output(t, options, "atc_asg_id"),
				terraform.Output(t, options, "worker_asg_id"),
				tc.region,
				tc.expected,
			)
		})
	}
}

func readGoldenFile(t *testing.T, path string) string {
	f, err := ioutil.ReadFile(path)
	if err != nil {
		t.Fatalf("failed to read golden file: %s", path)
	}
	return string(f)
}
