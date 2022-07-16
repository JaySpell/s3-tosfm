#Outputs for the TOSFM S3 bucket
output "tosfm-s3-name" {
    description = "Name of the bucket"
    value = aws_s3_bucket.s3-tosfm.id
}
