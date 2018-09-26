# AWS Serverless Application Demo

Terraform implementation of the exercise provided by AWS found [here](https://aws.amazon.com/getting-started/projects/build-serverless-web-app-lambda-apigateway-s3-dynamodb-cognito)

## Requirements

- AWS cli installed and configured with credentials for your target account
- A domain registered with AWS. See [here](https://docs.aws.amazon.com/AmazonS3/latest/dev/website-hosting-custom-domain-walkthrough.html) for details.

## ToDo

- [] get the api resources to work properly
- [] incorporate cloudfront
- [] auto certificate reqesting/confirmation via DNS
- [] split api gateway creation from api resources (one gateway to many resources)
- [] streamline lambda package zip/function creation (without creating too many dependencies..)

## ShoutOuts

- https://github.com/squidfunk/terraform-aws-api-gateway-enable-cors/blob/master/main.tf