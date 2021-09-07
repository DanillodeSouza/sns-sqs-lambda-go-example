#!/bin/bash
# Script to create the lambda

LAMBDA_NAME=lambda-example

# Creating lambda
echo "Creating lambda"

awslocal lambda create-function \
    --runtime go1.x \
    --handler lambda-example \
    --role=arn:aws:iam:local \
    --zip-file fileb:///bin/linux_amd64/lambda-example.zip \
    --function-name $LAMBDA_NAME \
    --environment '{
        "Variables":{
            "LOG_LEVEL":"debug",
            "AWS_ACCESS_KEY_ID": "test",
            "AWS_SECRET_ACCESS_KEY": "test"
        }
    }' \
    && echo "Created" || echo "Failed to create"

echo "Creating Event source mapping"
awslocal lambda create-event-source-mapping \
    --event-source-arn arn:aws:sqs:us-east-1:000000000000:queue-example \
    --function-name $LAMBDA_NAME \
    --batch-size 1 \
    && echo "Created event" || echo "Failed to create event"

echo "Lambda initialization completed"
