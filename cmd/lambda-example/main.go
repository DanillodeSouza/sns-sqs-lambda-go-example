package main

import (
	"context"
	"encoding/json"
	"fmt"

	processor "github.com/DanillodeSouza/sns-sqs-lambda-go-example/processor"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handle(ctx context.Context, sqsEvent events.SQSEvent) error {
	config := processor.NewConfig()
	logger, err := processor.NewLogger(config.LogLevel)
	if err != nil {
		panic(err)
	}
	defer logger.Sync()

	exampleRepository := processor.NewExampleRepository(*config)
	sqsRepository, err := processor.NewSqsRepository(config.AWSRegion, config.SQSDestinationEndpoint)
	if err != nil {
		panic(err)
	}

	for _, record := range sqsEvent.Records {
		messageBody := make(map[string]string)
		messageData := make(map[string]interface{})

		err = json.Unmarshal([]byte(record.Body), &messageBody)
		if err != nil {
			processor.LogError(logger, fmt.Sprintf("Unmarshal message body error: %s", err.Error()))
			return err
		}

		err := json.Unmarshal([]byte(messageBody["Message"]), &messageData)
		if err != nil {
			processor.LogError(logger, fmt.Sprintf("Unmarshal message data error: %s", err.Error()))
			return err
		}

		result, err := exampleRepository.Get(messageData)
		if err != nil {
			processor.LogError(logger, fmt.Sprintf("Get result error: %s", err.Error()))
			return err
		}

		jsonResult, _ := json.Marshal(result)
		processor.LogInfo(logger, "config.AWSRegion")
		processor.LogInfo(logger, config.AWSRegion)

		processor.LogInfo(logger, "config.SQSDestinationEndpoint")
		processor.LogInfo(logger, config.SQSDestinationEndpoint)

		err = sqsRepository.SendMessage(ctx, config.SQSDestinationEndpoint, jsonResult)
		if err != nil {
			processor.LogError(logger, fmt.Sprintf("Send message error: %s", err.Error()))
			return err
		}
	}
	return nil
}

func main() {
	lambda.Start(handle)
}
