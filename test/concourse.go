package concourse

import (
	"encoding/json"
	"net/http"
	"net/url"
	"path"
	"testing"

	"github.com/stretchr/testify/assert"

	asg "github.com/telia-oss/terraform-aws-asg/v3/test"
)

// Expectations for the Concourse test suite
type Expectations struct {
	Version           string
	WorkerVersion     string
	ATCAutoscaling    asg.Expectations
	WorkerAutoscaling asg.Expectations
}

// RunTestSuite runs the test suite against the autoscaling group.
func RunTestSuite(t *testing.T, endpoint, atcASGName, workerASGName string, region string, expected Expectations) {
	// Run test suites for the autoscaling groups.
	asg.RunTestSuite(t, atcASGName, region, expected.ATCAutoscaling)
	asg.RunTestSuite(t, workerASGName, region, expected.WorkerAutoscaling)

	u, err := url.Parse(endpoint)
	if err != nil {
		t.Fatalf("failed to parse url from endpoint: %s", endpoint)
	}

	u.Path = path.Join(u.Path, "api", "v1", "info")

	r, err := http.Get(u.String())
	if err != nil {
		t.Fatalf("get-request error: %s", err)
	}
	defer r.Body.Close()

	assert.Equal(t, 200, r.StatusCode)

	var info concourseInfo
	err = json.NewDecoder(r.Body).Decode(&info)
	if err != nil {
		t.Fatalf("failed to deserialize JSON response: %s", err)
	}

	assert.Equal(t, expected.Version, info.Version)
	assert.Equal(t, expected.WorkerVersion, info.WorkerVersion)
}

type concourseInfo struct {
	Version       string `json:"version"`
	WorkerVersion string `json:"worker_version"`
}
