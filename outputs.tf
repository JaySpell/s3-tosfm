#Outputs for the TOSFM S3 bucket
output "tosfm-s3-name" {
    description = "Name of the bucket"
    value = aws_s3_bucket.s3-tosfm.id
}

output "tosfm-notification-queue" {
    description = "Notification queue"
    value = length(aws_sns_topic.s3-tosfm-sns) > 0 ? aws_sns_topic.s3-tosfm-sns[0].arn : aws_sqs_queue.s3-tosfm-sqs[0].arn
}