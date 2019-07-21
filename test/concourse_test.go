package concourse_test

import (
	"fmt"
	"testing"

	asg "github.com/telia-oss/terraform-aws-asg/test"
	concourse "github.com/telia-oss/terraform-aws-concourse/test"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

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
				},
			},
		},
	}

	for _, tc := range tests {
		tc := tc // Source: https://gist.github.com/posener/92a55c4cd441fc5e5e85f27bca008721
		t.Run(tc.description, func(t *testing.T) {
			t.Parallel()
			options := &terraform.Options{
				TerraformDir: tc.directory,

				Vars: map[string]interface{}{
					"name_prefix": tc.name,
					"packer_ami":  packerAMI
					"region":      tc.region,
				},

				EnvVars: map[string]string{
					"AWS_DEFAULT_REGION": tc.region,
				},
			}

			defer terraform.Destroy(t, options)
			terraform.InitAndApply(t, options)

			concourse.RunTestSuite(t,
				terraform.Output(t, options, "atc_autoscaling_group"),
				terraform.Output(t, options, "worker_autoscaling_group"),
				tc.region,
				tc.expected,
			)
		})
	}
}
