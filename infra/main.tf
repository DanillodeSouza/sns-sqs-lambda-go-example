terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  backend "s3" {
    encrypt = true
    bucket  = "state-bucket-teste"
    region  = "us-west-2"
    key     = "snssqslambdagoexample.tfstate"
  }

  required_version = ">= 0.12.9"
}

# - Criar SNS
# - Criar sqs
# - Criar policies
# - Criar lambda
# - Criar sqs
# - Criar dead letter
# - Criar lambda

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

/* SNS */
resource "aws_iam_role" "sns_delivery_status_role" {
  name        = "sns-delivery-status-role"
  description = "The IAM role permitted to receive success/failure feedback for this topic"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "sns_delivery_status_policy" {
  role   = aws_iam_role.sns_delivery_status_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:PutMetricFilter",
        "logs:PutRetentionPolicy"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

module "example_sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "2.0.0"

  name                          = "example-sns-topic"
  sqs_failure_feedback_role_arn = aws_iam_role.sns_delivery_status_role.arn
  sqs_success_feedback_role_arn = aws_iam_role.sns_delivery_status_role.arn
}
/* SNS */

/* FIRST SQS */
data "aws_iam_policy_document" "sns_sqs_queue_policy" {
  statement {
    sid    = "example-sns-topic"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "SQS:SendMessage",
    ]

    resources = [
      "arn:aws:sqs:${var.region}:*:first-sqs",
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        module.example_sns_topic.this_sns_topic_arn
      ]
    }
  }
}

module "first_sqs" {
  source = "github.com/terraform-aws-modules/terraform-aws-sqs"

  name   = "first-sqs"
  policy = data.aws_iam_policy_document.sns_sqs_queue_policy.json
}

resource "aws_sns_topic_subscription" "event_topic_subscription" {
  topic_arn = module.example_sns_topic.this_sns_topic_arn
  protocol  = "sqs"
  endpoint  = module.first_sqs.sqs_queue_arn
}
/* FIRST SQS */

/* FIRST LAMBDA */
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "read_sqs_policy" {
  name        = "ReceiveMessageSQSPolicy"
  path        = "/"
  description = "Receive message policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Effect": "Allow",
      "Resource": "${module.first_sqs.sqs_queue_arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role" "handle_message_role" {
  name = "ReceiveMessageSQSRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_receive_message_sqs" {
  role       = aws_iam_role.handle_message_role.name
  policy_arn = aws_iam_policy.read_sqs_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_logging" {
  role       = aws_iam_role.handle_message_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

module "example_lambda_function" {
  source = "github.com/terraform-aws-modules/terraform-aws-lambda"

  function_name = "example_lambda_function"
  description   = "My awesome lambda function"
  handler       = "lambda-example"
  runtime       = "go1.x"

  environment_variables = {
    SQS_DESTINATION_ENDPOINT = module.second_sqs.sqs_queue_id
  }

  create_role = false
  lambda_role = aws_iam_role.handle_message_role.arn

  create_package         = false
  local_existing_package = "../bin/linux_amd64/lambda-example.zip"
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = module.first_sqs.sqs_queue_arn
  function_name    = module.example_lambda_function.lambda_function_arn
  batch_size       = "1"
}

resource "aws_iam_policy" "send_sqs_message_policy" {
  name        = "SendMessageSQSPolicy"
  path        = "/"
  description = "Send message policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sqs:SendMessage",
      "Effect": "Allow",
      "Resource": "${module.second_sqs.sqs_queue_arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_sqs" {
  role       = aws_iam_role.handle_message_role.name
  policy_arn = aws_iam_policy.send_sqs_message_policy.arn
}
/* FIRST LAMBDA */

module "sqs_dead_letter" {
  source = "github.com/terraform-aws-modules/terraform-aws-sqs"

  name = var.sqs_deadletter_queue_name
}

module "second_sqs" {
  source = "github.com/terraform-aws-modules/terraform-aws-sqs"

  name = var.sqs_queue_name
  redrive_policy = jsonencode({
    deadLetterTargetArn = module.sqs_dead_letter.sqs_queue_arn
    maxReceiveCount     = 4
  })
}
