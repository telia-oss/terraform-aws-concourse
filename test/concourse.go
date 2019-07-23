package concourse

import (
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"

	asg "github.com/telia-oss/terraform-aws-asg/v3/test"
)

// Expectations for the Concourse test suite
type Expectations struct {
	ATCAutoscaling    asg.Expectations
	WorkerAutoscaling asg.Expectations
}

// RunTestSuite runs the test suite against the autoscaling group.
func RunTestSuite(t *testing.T, atcASGName, workerASGName string, region string, expected Expectations) {
	_ = NewSession(t, region)

	asg.RunTestSuite(t, atcASGName, region, expected.ATCAutoscaling)
	asg.RunTestSuite(t, workerASGName, region, expected.WorkerAutoscaling)
}

func NewSession(t *testing.T, region string) *session.Session {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
	if err != nil {
		t.Fatalf("failed to create new AWS session: %s", err)
	}
	return sess
}
