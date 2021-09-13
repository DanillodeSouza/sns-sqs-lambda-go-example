variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "sqs_queue_name" {
  description = "Value of the Sqs Queue Name"
  type        = string
  default     = "queue"
}

variable "sqs_deadletter_queue_name" {
  description = "Value of the Sqs Dead Letter Queue Name"
  type        = string
  default     = "deadletter-queue"
}
