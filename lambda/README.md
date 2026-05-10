# Lambda package

`app.py` implements the `/health` handler. The function validates that the request body is valid JSON and contains a top-level `payload` key before writing the request record to DynamoDB.

The Terraform `archive_file` data source packages this directory into the Lambda deployment ZIP.
