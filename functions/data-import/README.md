# Data Import Lambda Function

AWS Lambda function for importing data from S3 to RDS PostgreSQL database.

## Overview

This Lambda function is triggered when a file is uploaded to an S3 bucket. It processes the file and imports the data into an RDS PostgreSQL database. The function supports various file formats and can handle different types of data imports.

## Features

- Automatic processing of files uploaded to S3
- Secure database connection using AWS Secrets Manager
- Error handling and logging
- Support for CSV and JSON file formats
- Transaction support for data integrity

## Prerequisites

- AWS account with appropriate permissions
- S3 bucket for data files
- RDS PostgreSQL database
- AWS Secrets Manager secret containing database credentials

## Configuration

The Lambda function uses the following environment variables:

- `DB_SECRET_ARN`: ARN of the Secrets Manager secret containing database credentials
- `TARGET_BUCKET`: Name of the S3 bucket where data files are uploaded
- `LOG_LEVEL`: Logging level (default: INFO)

## Deployment

1. Install dependencies:

   ```
   npm install
   ```

2. Build the package:

   ```
   npm run build
   ```

3. Deploy using AWS CLI or your preferred deployment method:
   ```
   aws lambda update-function-code --function-name data-import --zip-file fileb://dist/function.zip
   ```

## Testing

Run the tests using Jest:

```
npm test
```

## Development

The main components of the Lambda function are:

- `getDatabaseCredentials`: Retrieves database credentials from Secrets Manager
- `connectToDatabase`: Establishes a connection to the PostgreSQL database
- `processS3Event`: Processes an S3 event and imports the data
- `handler`: Main Lambda handler function

## Error Handling

The function includes comprehensive error handling for:

- S3 access issues
- Database connection failures
- Data parsing errors
- Import failures

All errors are logged for troubleshooting.
