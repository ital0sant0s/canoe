# Event Processing Service

A scalable event processing system built with Flask API service running on ECS Fargate and Lambda functions for event consumption, using AWS MSK (Managed Streaming for Apache Kafka) for event streaming.

## Application Overview

This event processing service consists of two main components:

### API Service (Flask Application)
- **Location**: `src/api-service/app.py`
- **Purpose**: REST API that provides endpoints and publishes to Kafka
- **Framework**: Flask with Gunicorn WSGI server
- **Endpoints**:
  - `GET /hello` - Returns {"message": "Hello World!"}
  - `GET /current_time?name=some_name` - Returns timestamp and message, publishes to Kafka
  - `GET /healthcheck` - Service health check
- **Dependencies**: Flask, confluent-kafka

### Event Processor (Lambda Function)
- **Location**: `src/event-processor/lambda_function.py`
- **Purpose**: Consumes events from Kafka topics and processes them
- **Trigger**: AWS MSK (Kafka) event source mapping
- **Runtime**: Python 3.12

## Architecture

For a detailed view of the system architecture and infrastructure components, see the [Infrastructure Diagram](docs/infrastructure-diagram.md).

## Docker Image Build

Build the Docker image for the API service:

```bash
docker build -f docker/api-service.Dockerfile -t event-processing-api .
```

For production with version tag:
```bash
docker build -f docker/api-service.Dockerfile -t event-processing-api:v1.0.0 .
```

The Dockerfile uses multi-stage build for optimized image size and includes:
- Python 3.12 slim base image
- Non-root user for security
- Health check endpoint
- Gunicorn with 4 workers

## Running Locally with Docker Compose

### Prerequisites
- Docker and Docker Compose installed
- Make utility (pre-installed on macOS/Linux, available on Windows)
- At least 4GB RAM available for containers

### Quick Start

Start the complete local development environment:
```bash
make up
```

This will start:
- **Kafka**: Message broker on port 9092 (KRaft mode, no Zookeeper needed)
- **API Service**: Flask application on port 5001
- **Event Processor**: Consumer that processes Kafka messages
- **Kafka UI**: Web interface on port 8080

### Available Make Commands

View all available commands:
```bash
make help
```

Common development commands:
```bash
make up          # Start all services
make down        # Stop all services
make restart     # Restart all services
make test        # Run automated tests
make health      # Check service health
make status      # Show service status
make logs        # View all logs
make clean       # Stop and remove volumes
```

### Testing the Local Setup

Run the automated test suite:
```bash
make test
```

Or test manually:
```bash
curl http://localhost:5001/healthcheck
curl http://localhost:5001/hello
curl "http://localhost:5001/current_time?name=John"
curl "http://localhost:5001/current_time?name=Alice"
```

### Monitoring and Debugging

View logs in real-time:
```bash
make logs           # All services
make logs-api       # API service only
make logs-processor # Event processor only
make logs-kafka     # Kafka only
```

Access Kafka UI for topic management: http://localhost:8080

Check service status:
```bash
make status
```

### Kafka Management

```bash
make topics        # List Kafka topics
make create-topic  # Create events topic
```

### Stopping Services

```bash
make down       # Stop all services
make clean      # Stop and remove volumes
make clean-all  # Remove everything including images
```

## AWS Deployment

### Prerequisites for AWS Deployment
- AWS CLI configured with appropriate permissions
- Docker installed
- Terraform installed
- jq installed (for ECS deployments)

### Infrastructure Deployment

Deploy infrastructure using Terraform:

```bash
make tf-plan       # Plan infrastructure changes
make tf-apply      # Apply infrastructure changes
```

Or use the script directly:
```bash
./scripts/deploy.sh
```

### Application Deployment

Complete deployment workflow:

```bash
# 1. Build and tag Docker image for ECR
make aws-build

# 2. Push image to ECR
make aws-push

# 3. Deploy to ECS
make aws-deploy
```

With specific image tags:
```bash
# Build with specific tag
IMAGE_TAG=v1.2.3 make aws-build

# Push specific tag
IMAGE_TAG=v1.2.3 make aws-push

# Deploy specific tag
IMAGE_TAG=v1.2.3 make aws-deploy
```

### Manual Script Usage

You can also use the scripts directly:

```bash
# Build image
IMAGE_TAG=v1.0.0 ./scripts/build.sh

# Push to ECR
IMAGE_TAG=v1.0.0 ./scripts/push.sh

# Deploy to ECS
IMAGE_TAG=v1.0.0 ./scripts/deploy-ecs.sh
```

### Environment Variables

Available environment variables for deployment:

- `PROJECT_NAME` - Project name (default: event-processing-service)
- `AWS_REGION` - AWS region (default: us-east-1)
- `IMAGE_TAG` - Docker image tag (default: latest)

### Deployment Process

1. **Infrastructure First**: Deploy AWS infrastructure using Terraform
2. **Build Image**: Build Docker image with proper tags
3. **Push to ECR**: Push image to Elastic Container Registry
4. **Deploy to ECS**: Update ECS service with new image

### Configuration

Configure your deployment:

1. Set up terraform variables:
```bash
cp infrastructure/environments/prod/terraform.tfvars.example infrastructure/environments/prod/terraform.tfvars
# Edit terraform.tfvars with your values
```

2. Deploy infrastructure:
```bash
make tf-apply
```

3. Deploy application:
```bash
IMAGE_TAG=v1.0.0 make aws-build
IMAGE_TAG=v1.0.0 make aws-push
IMAGE_TAG=v1.0.0 make aws-deploy
```

## Running Individual Docker Containers

For testing individual components, you can run the API service alone:

```bash
docker build -f docker/api-service.Dockerfile -t event-processing-api .
docker run -d --name api-service -p 5000:5000 \
  -e KAFKA_BOOTSTRAP_SERVERS=localhost:9092 \
  -e KAFKA_TOPIC=events \
  event-processing-api:latest
```

Stop and remove:
```bash
docker stop api-service && docker rm api-service
```

## Tagging and Pushing to ECR

### 1. Authenticate Docker to ECR
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### 2. Create ECR Repository (if not exists)
```bash
aws ecr create-repository --repository-name event-processing-api --region us-east-1
```

### 3. Tag the Image
```bash
docker tag event-processing-api:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/event-processing-api:latest
docker tag event-processing-api:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/event-processing-api:v1.0.0
```

### 4. Push to ECR
```bash
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/event-processing-api:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/event-processing-api:v1.0.0
```

## Lambda Function Local Invocation

### Method 1: Direct Python Execution
```bash
cd src/event-processor
python3 -c "
import json
from lambda_function import lambda_handler

event = {
  'records': {
    'events-0': [{
      'topic': 'events',
      'partition': 0,
      'offset': 1,
      'timestamp': 1640995200000,
      'timestampType': 'CREATE_TIME',
      'key': 'test_key',
      'value': '{\"id\":\"test_123\",\"user\":\"test\",\"message\":\"Hello test\",\"timestamp\":1640995200}'
    }]
  }
}

context = type('Context', (), {
    'function_name': 'test-function',
    'function_version': '1',
    'invoked_function_arn': 'arn:aws:lambda:us-east-1:123456789012:function:test-function',
    'memory_limit_in_mb': 128,
    'remaining_time_in_millis': lambda: 30000,
    'log_group_name': '/aws/lambda/test-function',
    'log_stream_name': '2023/01/01/[$LATEST]test123',
    'aws_request_id': 'test-request-id'
})()

result = lambda_handler(event, context)
print('Result:', json.dumps(result, indent=2))
"
```

### Method 2: Using AWS SAM CLI (if SAM template exists)
```bash
sam local invoke EventProcessorFunction --event test-event.json
```

### Method 3: Create Test Event File
Create `test-event.json`:
```json
{
  "records": {
    "events-0": [{
      "topic": "events",
      "partition": 0,
      "offset": 1,
      "timestamp": 1640995200000,
      "timestampType": "CREATE_TIME",
      "key": "test_key",
      "value": "{\"id\":\"test_123\",\"user\":\"test\",\"message\":\"Hello test\",\"timestamp\":1640995200}"
    }]
  }
}
```

Then invoke:
```bash
cd src/event-processor
python3 -c "
import json
from lambda_function import lambda_handler

with open('../../test-event.json', 'r') as f:
    event = json.load(f)

result = lambda_handler(event, None)
print('Result:', json.dumps(result, indent=2))
"
```

## Environment Variables

### API Service
- `KAFKA_BOOTSTRAP_SERVERS`: Kafka cluster endpoints (default: localhost:9092)
- `KAFKA_TOPIC`: Topic name for publishing events (default: events)
- `PORT`: Service port (default: 5000)

### Lambda Function
- `LOG_LEVEL`: Logging level (default: INFO)

## Infrastructure Deployment

Deploy the infrastructure using Terraform:

```bash
cd infrastructure/environments/prod
terraform init
terraform plan -var="project_name=event-processing-service" -var="aws_region=us-east-1"
terraform apply
```

For development environment:
```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

## Project Structure

```
event-processing-service/
├── src/
│   ├── api-service/          # Flask API service
│   │   ├── app.py           # Main application
│   │   └── requirements.txt # Dependencies
│   └── event-processor/      # Lambda function
│       ├── lambda_function.py # Event processor
│       └── requirements.txt   # Lambda dependencies
├── docker/
│   └── api-service.Dockerfile # API service container
├── infrastructure/           # Terraform configuration
│   ├── environments/
│   │   └── prod/            # Production environment
│   └── modules/             # Reusable modules
└── README.md                # This file
```

## Monitoring

### CloudWatch Logs
- API Service: `/ecs/event-processing-service-api-service/event-processing-service`
- Lambda Function: `/aws/lambda/event-processing-service-event-processor`

### Health Checks
- API Health: `GET /health`
- Container Health: Docker HEALTHCHECK every 30s

## Future Improvements

This section outlines potential enhancements to make the event processing service more production-ready and enterprise-grade.

### 1. CI/CD Pipeline Implementation

**Current State**: Manual deployment using scripts (`build.sh`, `push.sh`, `deploy-ecs.sh`)

**Recommended Improvements**:
- **GitHub Actions**: Implement automated CI/CD pipelines
- **Multi-Environment Deployment**: Automated promotion from dev → staging → production
- **Infrastructure as Code**: Terraform plan/apply automation with state management
- **Security Scanning**: Container vulnerability scanning, SAST/DAST integration
- **Automated Testing**: Unit tests, integration tests, and smoke tests in pipeline
- **Rollback Strategy**: Automated rollback on deployment failures

### 2. API Best Practices & Versioning

**Current State**: Simple REST API without versioning

**Recommended Improvements**:
- **API Versioning**: Implement semantic versioning (e.g., `/v1/hello`, `/v2/current_time`)
- **OpenAPI/Swagger Documentation**: Auto-generated API documentation
- **Rate Limiting**: Implement request throttling to prevent abuse
- **Request/Response Validation**: Schema validation for all endpoints
- **Standardized Error Responses**: Consistent error format across all endpoints
- **Correlation IDs**: Request tracing for better debugging
- **Content Negotiation**: Support for JSON/XML response formats
- **CORS Configuration**: Proper Cross-Origin Resource Sharing setup

**Example API Structure**:
```
GET /v1/health           - Enhanced health check with dependencies
GET /v1/hello           - Basic greeting endpoint
GET /v1/current_time    - Time endpoint with enhanced metadata
POST /v1/events         - Direct event publishing endpoint
GET /v1/metrics         - Application metrics endpoint
```

### 3. Enhanced Health Check System

**Current State**: Basic health check returning 200 status

**Recommended Improvements**:
- **Deep Health Checks**: Verify database, Kafka, and external service connectivity
- **Health Check Levels**: 
  - `/health/live` - Basic liveness probe
  - `/health/ready` - Readiness probe with dependency checks
- **Health Metrics**: Response time, dependency status, resource utilization
- **Graceful Degradation**: Partial functionality when some dependencies are down
- **Health Check Caching**: Cache health status to reduce overhead

**Example Enhanced Response**:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "version": "v1.2.3",
  "dependencies": {
    "kafka": {"status": "healthy", "latency_ms": 5},
    "database": {"status": "healthy", "latency_ms": 2}
  },
  "metrics": {
    "uptime_seconds": 86400,
    "memory_usage_mb": 256,
    "cpu_usage_percent": 15
  }
}
```

### 4. Security Enhancements

**Current State**: Basic ALB with ACM certificate

**Recommended Security Improvements**:

#### AWS WAF
- **DDoS Protection**: Rate limiting and request filtering
- **OWASP Top 10 Protection**: SQL injection, XSS, and other attack prevention
- **Geo-blocking**: Restrict access by geographic location
- **IP Whitelisting/Blacklisting**: Control access by IP ranges
- **Bot Protection**: Detect and block malicious bots

#### Additional Security Measures
- **AWS Shield Advanced**: Enhanced DDoS protection
- **VPC Flow Logs**: Network traffic monitoring
- **Secrets Manager**: Secure credential management instead of environment variables
- **IAM Least Privilege**: Minimal required permissions for all services
- **Network ACLs**: Additional network-level security
- **Encryption**: End-to-end encryption for data in transit and at rest

### 5. Observability & Monitoring

**Current State**: Basic CloudWatch logging

**Recommended Improvements**:
- **Distributed Tracing**: AWS X-Ray or OpenTelemetry integration
- **Structured Logging**: JSON-formatted logs with correlation IDs
- **Custom Metrics**: Business and application-specific metrics
- **Alerting**: CloudWatch alarms for critical metrics
- **Dashboard**: Real-time monitoring dashboard
- **Log Aggregation**: Centralized logging with search capabilities
- **Performance Monitoring**: APM tools for application performance insights

### 6. Data & Event Processing Enhancements

**Current State**: Basic Kafka producer/consumer

**Recommended Improvements**:
- **Event Schema Registry**: Centralized schema management for Kafka messages
- **Dead Letter Queues**: Handle failed message processing
- **Event Replay**: Ability to replay events for data recovery
- **Event Sourcing**: Complete audit trail of all events

### 7. Scalability & Performance

**Current State**: Basic ECS Fargate with manual scaling

**Recommended Improvements**:
- **Auto Scaling**: CPU/memory-based automatic scaling
- **Load Testing**: Regular performance testing and benchmarking
- **Caching Layer**: Redis/ElastiCache for frequently accessed data
- **CDN Integration**: CloudFront for static content delivery
- **Resource Optimization**: Right-sizing of compute resources

### 8. Disaster Recovery & Business Continuity

**Current State**: Single-region deployment

**Recommended Improvements**:
- **Multi-Region Deployment**: Consider Multi-Region deploy
- **Backup Strategy**: Automated backups with point-in-time recovery
- **Data Replication**: Cross-region data synchronization
- **Recovery Testing**: Regular disaster recovery drills

### 9. Compliance & Governance

**Recommended Additions**:
- **Data Retention Policies**: Automated data lifecycle management

### 10. Development Experience

**Current State**: Manual local development setup

**Recommended Improvements**:
- **Development Containers**: Consistent dev environment with Docker
- **Local Testing**: Complete local testing environment with test data
- **API Mocking**: Mock services for external dependencies
- **Code Quality**: Automated linting, formatting, and code analysis
- **Documentation**: Auto-generated documentation from code
