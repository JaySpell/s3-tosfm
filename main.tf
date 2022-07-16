#Creates a Typical Object Store For Messaging (TOSFM)
#Event notification via SNS or SQS - defaults to SNS

#Template provides an S3 bucket used for messaging 
provider "aws" {
  profile = "default"
  region  = var.tosfm-aws-region
}

#Module variables
variable "tosfm-create-sqs-queue" {
  description = "If set to true creates an SQS queue for notification instead of SNS"
  type = bool
  default = false
}

variable "tosfm-aws-region" {
  description = "Set to the region where resources will be created"
  type = string  
}

variable "tosfm-access-arn" {
  description = "ARN for access"
  type = string
}

variable "tosfm-s3-allow-public-access" {
  description = "Block public access for bucket"
  type = bool  
  default = true
}

resource "random_id" "tosfm-id" {
	  byte_length = 8
}

#S3 Object Store for Messaging
resource "aws_s3_bucket" "s3-tosfm" {
    bucket = "tosfm-${random_id.tosfm-id.hex}"
    tags = {
        tf_template = "s3_tosfm_v0.1"
    }

}

#S3 Bucket Policy
resource "aws_s3_bucket_policy" "s3-tosfm-policy" {
  bucket = aws_s3_bucket.s3-tosfm.id
  policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "AWS": "${var.tosfm-access-arn}"
          },
          "Action": [
            "s3:PutObject",
            "s3:ListBucket",
            "s3:GetObject"
          ],
          "Resource": [
            "${aws_s3_bucket.s3-tosfm.arn}",
            "${aws_s3_bucket.s3-tosfm.arn}/*"
          ]
        }
      ]
    }
  EOF
}

#S3 Public Access
resource "aws_s3_bucket_public_access_block" "tosfm-block-public-access" {
  bucket = aws_s3_bucket.s3-tosfm.id
  count = "${var.tosfm-s3-allow-public-access}" ? 1 : 0
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#S3 Bucket SQS Notification
resource "aws_sqs_queue" "s3-tosfm-sqs" {
  count = var.tosfm-create-sqs-queue ? 1 : 0
  name = "tosfm-${random_id.tosfm-id.hex}-event-notification-queue"
  policy = <<POLICY
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": "*",
                    "Action": "sqs:SendMessage",
                    "Resource": "arn:aws:sqs:*:*:tosfm-${random_id.tosfm-id.hex}-event-notification-queue",
                    "Condition": {
                        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.s3-tosfm.arn}" }
                    }
                }
            ]
        }
    POLICY
}

resource "aws_s3_bucket_notification" "sqs_queue_tosfm" {
  count = var.tosfm-create-sqs-queue ? 1 : 0
  bucket = aws_s3_bucket.s3-tosfm.id
  queue {
    queue_arn     = aws_sqs_queue.s3-tosfm-sqs[0].arn
    events        = ["s3:ObjectCreated:*"]
  }
}

#S3 Bucket SNS Notification
resource "aws_sns_topic" "s3-tosfm-sns" {
  count = var.tosfm-create-sqs-queue ? 0 : 1
  name = "${random_id.tosfm-id.hex}-sns-topic"
  policy = <<POLICY
    {
      "Version":"2012-10-17",
      "Statement":[{
          "Effect": "Allow",
          "Principal": { "Service": "s3.amazonaws.com" },
          "Action": "SNS:Publish",
          "Resource": "arn:aws:sns:*:*:${random_id.tosfm-id.hex}-sns-topic",
          "Condition":{
              "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.s3-tosfm.arn}"}
          }
      }]
    }
  POLICY
}

resource "aws_s3_bucket_notification" "sns_notification_tosfm" {
  count = var.tosfm-create-sqs-queue ? 0 : 1
  bucket = aws_s3_bucket.s3-tosfm.id
  topic {
    topic_arn     = aws_sns_topic.s3-tosfm-sns[0].arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = "*"
  }
}

