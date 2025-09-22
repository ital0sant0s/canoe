import json
import logging
import time
import os
from confluent_kafka import Consumer, KafkaError
from lambda_function import process_kafka_message

logging.basicConfig(
    level=getattr(logging, os.getenv('LOG_LEVEL', 'INFO')),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

def create_consumer():
    config = {
        'bootstrap.servers': os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092'),
        'group.id': os.getenv('KAFKA_GROUP_ID', 'event-processor-group'),
        'auto.offset.reset': 'earliest',
        'enable.auto.commit': True,
        'auto.commit.interval.ms': 1000,
        'session.timeout.ms': 6000,
        'heartbeat.interval.ms': 1000
    }

    consumer = Consumer(config)
    topic = os.getenv('KAFKA_TOPIC', 'events')
    consumer.subscribe([topic])

    logger.info(f"Consumer created and subscribed to topic: {topic}")
    return consumer

def main():
    consumer = create_consumer()

    try:
        logger.info("Starting event processor consumer...")

        while True:
            msg = consumer.poll(timeout=1.0)

            if msg is None:
                continue

            if msg.error():
                if msg.error().code() == KafkaError._PARTITION_EOF:
                    logger.info(f"End of partition reached {msg.topic()}/{msg.partition()}")
                else:
                    logger.error(f"Consumer error: {msg.error()}")
                continue

            try:
                kafka_record = {
                    'topic': msg.topic(),
                    'partition': msg.partition(),
                    'offset': msg.offset(),
                    'timestamp': msg.timestamp()[1] if msg.timestamp()[0] != -1 else int(time.time() * 1000),
                    'key': msg.key().decode('utf-8') if msg.key() else None,
                    'value': msg.value().decode('utf-8') if msg.value() else None
                }

                logger.info(f"Received message: {kafka_record['key']} from {kafka_record['topic']}")

                process_kafka_message(kafka_record)

                logger.info(f"Successfully processed message: {kafka_record['key']}")

            except Exception as e:
                logger.error(f"Error processing message: {str(e)}")
                logger.error(f"Message details: topic={msg.topic()}, partition={msg.partition()}, offset={msg.offset()}")

    except KeyboardInterrupt:
        logger.info("Consumer interrupted by user")
    except Exception as e:
        logger.error(f"Unexpected error in consumer: {str(e)}")
    finally:
        logger.info("Closing consumer")
        consumer.close()

if __name__ == "__main__":
    main()