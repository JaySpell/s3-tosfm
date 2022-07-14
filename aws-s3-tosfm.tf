#Template provides an S3 bucket used for messaging 
provider "aws" {
  profile = "default"
  region  = var.region
}

#Module variables
variable "s3-sqs-notification" {
  description = "If set to true creates an SQS queue for notification instead of SNS"
  type = bool
}

#S3 Object Store for Messaging
resource "aws_s3_bucket" "s3-tosfm" {
    bucket_name = var.bucket_name
    tags = {
        tf_template = "s3_tosfm_v0.1"
    }

}

#S3 Bucket Policy

#S3 Bucket SQS Notification
resource "aws_sqs_queue" "s3-tosfm-sqs" {
  count = var.s3-sqs-notification ? 1 : 0
  name = "s3-event-notification-queue"
  policy = <<POLICY
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": "*",
                    "Action": "sqs:SendMessage",
                    "Resource": "arn:aws:sqs:*:*:s3-event-notification-queue",
                    "Condition": {
                        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.s3-tosfm.arn}" }
                    }
                }
            ]
        }
    POLICY
}

resource "aws_s3_sqs_bucket_notification" "bucket_notification" {
  count = var.aws_s3_sqs_bucket_notification ? 1 : 0
  bucket = aws_s3_bucket.s3-tosfm.id
  queue {
    queue_arn     = aws_sqs_queue.s3-tosfm-sqs.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

#S3 Bucket SNS Notification
resource "aws_sns_queue" "s3-tosfm-sns" {
  count = var.aws_s3_sqs_bucket_notification ? 0 : 1
  policy = <<POLICY
    {
      "Version":"2012-10-17",
      "Statement":[{
          "Effect": "Allow",
          "Principal": { "Service": "s3.amazonaws.com" },
          "Action": "SNS:Publish",
          "Resource": "arn:aws:sns:*:*:s3-event-notification-topic",
          "Condition":{
              "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.bucket.arn}"}
          }
      }]
    }
  POLICY
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count = var.s3-sqs-notification ? 0 : 1
  bucket = aws_s3_bucket.s3-tosfm.id
  topic {
    topic_arn     = aws_sns_topic.s3-tosfm-sns.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}
