import base64
import json
import logging
import os
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Dict

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def _response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=str),
    }


def _parse_body(event: Dict[str, Any]) -> Dict[str, Any]:
    body = event.get("body")
    if body is None or body == "":
        raise ValueError("Request body must be valid JSON and include payload.")

    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")

    try:
        parsed = json.loads(body, parse_float=Decimal)
    except json.JSONDecodeError as exc:
        raise ValueError("Request body must be valid JSON.") from exc

    if not isinstance(parsed, dict) or "payload" not in parsed:
        raise ValueError("Request body must include a key named payload.")

    return parsed


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    logger.info("Incoming request event: %s", json.dumps(event, default=str))

    try:
        request_json = _parse_body(event)
    except ValueError as exc:
        return _response(400, {"status": "bad_request", "message": str(exc)})

    request_context = event.get("requestContext", {}) or {}
    identity = request_context.get("identity", {}) or {}

    item = {
        "id": str(uuid.uuid4()),
        "received_at": datetime.now(timezone.utc).isoformat(),
        "environment": os.environ.get("ENVIRONMENT", "unknown"),
        "request_id": request_context.get("requestId", "unknown"),
        "http_method": event.get("httpMethod", "unknown"),
        "path": event.get("path", "unknown"),
        "source_ip": identity.get("sourceIp", "unknown"),
        "user_agent": identity.get("userAgent", "unknown"),
        "query_string_parameters": event.get("queryStringParameters") or {},
        "headers": event.get("headers") or {},
        "payload": request_json["payload"],
    }

    try:
        table.put_item(Item=item)
    except ClientError:
        logger.exception("Failed to write health check request to DynamoDB")
        return _response(500, {"status": "error", "message": "Failed to save request."})

    return _response(
        200,
        {"status": "healthy", "message": "Request processed and saved."},
    )
