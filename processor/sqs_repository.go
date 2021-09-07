package processor

import (
	"context"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sqs"
)

// Sqs is a connection with an AWS SQS service
type Sqs struct {
	sqs *sqs.SQS
}

func (s Sqs) SendMessage(ctx context.Context, qURL string, message []byte) error {
	_, err := s.sqs.SendMessage(&sqs.SendMessageInput{
		DelaySeconds: aws.Int64(0),
		MessageBody:  aws.String(string(message)),
		QueueUrl:     &qURL,
	})

	if err != nil {
		return err
	}

	return nil
}

// NewSqs will connect to an SQS in a certain AWS Region.
func NewSqsRepository(region, endpoint string) (*Sqs, error) {
	awsConfig := createAwsConfig(region, endpoint)

	sess, err := session.NewSession(awsConfig)
	if err != nil {
		return nil, err
	}
	return &Sqs{sqs: sqs.New(sess)}, nil
}

func createAwsConfig(region, endpoint string) *aws.Config {
	config := aws.NewConfig()

	config.CredentialsChainVerboseErrors = aws.Bool(true)

	if endpoint != "" {
		config.WithEndpoint(endpoint)
	}
	if region != "" {
		config.WithRegion(region)
	}

	return config
}
