import json
import logging
import time
from typing import Any, Dict, List

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    try:
        processed_count = 0
        failed_count = 0

        for record in event.get('records', {}).values():
            for kafka_record in record:
                try:
                    process_kafka_message(kafka_record)
                    processed_count += 1
                except Exception as e:
                    logger.error(f"Failed to process record: {str(e)}")
                    failed_count += 1

        response = {
            'statusCode': 200,
            'processed': processed_count,
            'failed': failed_count,
            'timestamp': int(time.time())
        }

        logger.info(f"Batch processing complete: {json.dumps(response)}")
        return response

    except Exception as e:
        logger.error(f"Lambda execution error: {str(e)}")
        return {
            'statusCode': 500,
            'error': str(e),
            'timestamp': int(time.time())
        }

def process_kafka_message(record: Dict[str, Any]) -> None:
    try:
        message_value = record.get('value')
        if not message_value:
            logger.warning("Empty message value received")
            return

        message_data = json.loads(message_value)

        log_entry = {
            'event_id': message_data.get('id'),
            'event_type': message_data.get('type'),
            'user': message_data.get('user'),
            'message': message_data.get('message'),
            'original_timestamp': message_data.get('timestamp'),
            'processed_timestamp': int(time.time()),
            'kafka_metadata': {
                'topic': record.get('topic'),
                'partition': record.get('partition'),
                'offset': record.get('offset'),
                'timestamp': record.get('timestamp')
            }
        }

        logger.info(f"Event processed: {json.dumps(log_entry)}")

        if message_data.get('type') == 'time_request':
            logger.info(f"Time request processed for user: {message_data.get('user')}")

    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in message: {str(e)}")
        logger.error(f"Raw message: {record.get('value')}")
    except Exception as e:
        logger.error(f"Error processing message: {str(e)}")
        logger.error(f"Record: {json.dumps(record)}")