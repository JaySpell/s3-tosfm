# Terraform AWS TOSFM - Typical Object Store For Messaging
This is a terraform AWS module that provides an object store for messaging.  This will create a S3 bucket using either a SNS or SQS queue for event notification.  The default is SNS - SQS turned on by setting *tosfm-create-sqs-queue = true*

This template assumes that a process is established in code to remove objects (messages) from the bucket once they have been processed.  

## Testing
Copy the following code into a main.tf file.

```hcl
    provider "aws" {
        profile = "default"
        region  = us-east-2
    }

    module "aws-s3-tosfm" {
        source = "git::https://github.com/JaySpell/s3-tosfm"
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
```
Run the commands to initialize / plan / apply the template.  *This assumes AWS profile is already setup with necessary access...*

```sh
    terraform init
    terraform plan
    terraform apply -auto-approve
```

## Options

```sh
    tosfm-s3-allow-public-access = true | false #sets bucket to allow public access
    tosfm-create-sqs-queue = true | false #sets queue to SQS instead of SNS
```