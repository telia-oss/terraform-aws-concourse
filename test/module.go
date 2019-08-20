package module

import (
	"bytes"
	"encoding/json"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/stretchr/testify/assert"

	asg "github.com/telia-oss/terraform-aws-asg/v3/test"
)

type Expectations struct {
	Version           string
	WorkerVersion     string
	ATCAutoscaling    asg.Expectations
	WorkerAutoscaling asg.Expectations
}

func RunTestSuite(t *testing.T, endpoint, atcASGName, workerASGName, adminUser, adminPassword, region string, expected Expectations) {
	// Run test suites for the autoscaling groups.
	asg.RunTestSuite(t, atcASGName, region, expected.ATCAutoscaling)
	asg.RunTestSuite(t, workerASGName, region, expected.WorkerAutoscaling)

	info := GetConcourseInfo(t, endpoint)
	assert.Equal(t, expected.Version, info.Version)
	assert.Equal(t, expected.WorkerVersion, info.WorkerVersion)

	sess := NewSession(t, region)
	targetGroups := DescribeTargetGroups(t, sess, atcASGName)
	for _, group := range targetGroups {
		assert.Equal(t, "InService", aws.StringValue(group.State))
	}

	// Download and install fly binary.
	tempDir, err := ioutil.TempDir("", "terraform-aws-concourse")
	if err != nil {
		t.Fatalf("failed to create temporary directory for fly binary: %s", err)
	}
	defer os.RemoveAll(tempDir)

	fly := &Fly{
		Endpoint:  endpoint,
		Directory: tempDir,
		Target:    "terraform-aws-concourse",
	}

	fly.Setup(t, adminUser, adminPassword)

	workers := fly.Workers(t)
	assert.Equal(t, int(expected.WorkerAutoscaling.MinSize), len(workers))
	for _, worker := range workers {
		assert.Equal(t, "linux", worker.Platform)
		assert.Equal(t, "running", worker.State)
	}
}

func parseURL(t *testing.T, endpoint string) *url.URL {
	u, err := url.Parse(endpoint)
	if err != nil {
		t.Fatalf("failed to parse url from endpoint: %s", endpoint)
	}
	return u
}

func GetConcourseInfo(t *testing.T, endpoint string) ConcourseInfo {
	u := parseURL(t, endpoint)
	u.Path = path.Join(u.Path, "api", "v1", "info")

	r, err := http.Get(u.String())
	if err != nil {
		t.Fatalf("get-request error: %s", err)
	}
	defer r.Body.Close()

	if r.StatusCode != http.StatusOK {
		t.Errorf("got non-200 response: %d", r.StatusCode)
	}

	var info ConcourseInfo
	err = json.NewDecoder(r.Body).Decode(&info)
	if err != nil {
		t.Fatalf("failed to deserialize JSON response: %s", err)
	}
	return info
}

type ConcourseInfo struct {
	Version       string `json:"version"`
	WorkerVersion string `json:"worker_version"`
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

func DescribeTargetGroups(t *testing.T, sess *session.Session, asgName string) []*autoscaling.LoadBalancerTargetGroupState {
	c := autoscaling.New(sess)

	out, err := c.DescribeLoadBalancerTargetGroups(&autoscaling.DescribeLoadBalancerTargetGroupsInput{
		AutoScalingGroupName: aws.String(asgName),
	})
	if err != nil {
		t.Fatalf("failed to describe load balancer target groups: %s", err)
	}
	return out.LoadBalancerTargetGroups
}

type Fly struct {
	Endpoint  string
	Directory string
	Target    string
	bin       string
}

func (f *Fly) Setup(t *testing.T, username, password string) {
	u := parseURL(t, f.Endpoint)
	q := u.Query()

	q.Set("arch", "amd64")
	q.Set("platform", runtime.GOOS)

	u.Path = path.Join(u.Path, "api", "v1", "cli")
	u.RawQuery = q.Encode()

	f.bin = filepath.Join(f.Directory, "fly")
	file, err := os.Create(f.bin)
	if err != nil {
		t.Fatalf("failed to create new file: %s", err)
	}
	defer file.Close()

	resp, err := http.Get(u.String())
	if err != nil {
		t.Fatalf("failed to get fly: %s", err)
	}
	defer resp.Body.Close()

	_, err = io.Copy(file, resp.Body)
	if err != nil {
		t.Fatalf("failed to write fly to disk: %s", err)
	}

	err = file.Chmod(0755)
	if err != nil {
		t.Fatalf("failed to change fly permissions: %s", err)
	}

	cmd := exec.Command(f.bin, "--target", f.Target, "login", "--team-name", "main", "--concourse-url", f.Endpoint, "--username", username, "--password", password)
	_, err = cmd.CombinedOutput()
	if err != nil {
		t.Errorf("failed to login to concourse: %s", err)
	}
}

func (f *Fly) Workers(t *testing.T) []*ConcourseWorker {
	cmd := exec.Command(f.bin, "--target", f.Target, "workers", "--json")
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Errorf("failed to list workers: %s", err)
	}

	r := bytes.NewReader(out)

	var workers []*ConcourseWorker
	err = json.NewDecoder(r).Decode(&workers)
	if err != nil {
		t.Fatalf("failed to deserialize workers: %s", err)
	}
	return workers
}

type ConcourseWorker struct {
	Platform string `json:"platform"`
	State    string `json:"state"`
}
