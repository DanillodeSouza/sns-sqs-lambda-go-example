#!/bin/bash
# Script to create sqs queue and sns subscription

SQS_QUEUE_NAME=queue-example
SQS_DESTINATION_QUEUE_NAME=queue-destination-example

# List queues
SQS_LIST=$(awslocal sqs list-queues)

awslocal sqs create-queue \
    --queue-name $SQS_QUEUE_NAME \
    && echo "Created" || echo "Failed to create"

awslocal sqs create-queue \
    --queue-name $SQS_DESTINATION_QUEUE_NAME \
    && echo "Created" || echo "Failed to create"

echo "Subscribing queue to SNS topic"
awslocal sns subscribe \
--topic-arn arn:aws:sns:us-east-1:000000000000:sns-topic-example \
--protocol sqs --notification-endpoint http://localhost:4566/000000000000/queue-example

echo "Sqs initialization completed"
