from flask import Flask, jsonify, request
import json
import logging
import time
import sys
import os
from confluent_kafka import Producer
from confluent_kafka import KafkaError

app = Flask(__name__)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)

logger = logging.getLogger(__name__)

KAFKA_BOOTSTRAP_SERVERS = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092')
KAFKA_TOPIC = os.getenv('KAFKA_TOPIC', 'events')

producer_config = {
    'bootstrap.servers': KAFKA_BOOTSTRAP_SERVERS,
    'retries': 3,
    'retry.backoff.ms': 1000,
    'acks': 'all',
    'compression.type': 'snappy'
}

producer = Producer(producer_config)

@app.before_request
def log_request():
    log_data = {
        'timestamp': int(time.time()),
        'method': request.method,
        'path': request.path,
        'query_string': request.query_string.decode('utf-8'),
        'remote_addr': request.remote_addr,
        'user_agent': request.headers.get('User-Agent', '')
    }
    logger.info(f"Request: {json.dumps(log_data)}")

@app.route('/hello', methods=['GET'])
def hello():
    return jsonify({'message': 'Hello World!'}), 200

@app.route('/current_time', methods=['GET'])
def current_time():
    try:
        name = request.args.get('name', 'Anonymous')
        timestamp = int(time.time())

        response_data = {
            'timestamp': timestamp,
            'message': f'Hello {name}'
        }

        event_data = {
            'timestamp': timestamp,
            'message': f'Hello {name}',
            'name': name
        }

        producer.produce(
            KAFKA_TOPIC,
            key=f"time_{timestamp}",
            value=json.dumps(event_data)
        )
        producer.flush()

        logger.info(f"Published to Kafka: {json.dumps(event_data)}")

        return jsonify(response_data), 200

    except Exception as e:
        logger.error(f"Error in current_time endpoint: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/healthcheck', methods=['GET'])
def healthcheck():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5000)), debug=False)