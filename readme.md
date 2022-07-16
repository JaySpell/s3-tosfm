# Terraform AWS TOSFM - Typical Object Store For Messaging
This is a terraform AWS module that provides an object store for messaging.  This will create a S3 bucket using either a SNS or SQS queue for event notification.  The default is SNS - SQS turned on by sending *tosfm-create-sqs-queue = true*

## Usage
''' 
    provider "aws" {
        profile = "default"
        region  = us-east-2
    }

    module "aws-s3-tosfm" {
        source = "../modules/s3-tosfm"
        tosfm-aws-region = "us-east-2"
        tosfm-access-arn = **ROLE_ARN_FOR_ACCESS**
        tosfm-create-sqs-queue = true
    }

    output "tosfm-s3-name" {
        description = "Name of the bucket"
        value = module.aws-s3-tosfm.tosfm-s3-name
    }

    output "tosfm-queue-arn" {
        description = "ARN of the queue"
        value = module.aws-s3-tosfm.tosfm-notification-queue
    }
'''

## Options

*tosfm-s3-allow-public-access* (boolean)
