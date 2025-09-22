.PHONY: help build up down logs test clean build-api build-processor health status topics aws-build aws-push aws-deploy tf-plan tf-apply

.DEFAULT_GOAL := help

help:
	@echo "Event Processing Service - Development Commands"
	@echo ""
	@echo "Local Development:"
	@echo "  up              Start all services in background"
	@echo "  down            Stop all services"
	@echo "  restart         Restart all services"
	@echo "  logs            Show logs from all services"
	@echo "  logs-api        Show API service logs"
	@echo "  logs-processor  Show event processor logs"
	@echo "  logs-kafka      Show Kafka logs"
	@echo ""
	@echo "Building:"
	@echo "  build           Build all Docker images"
	@echo "  build-api       Build API service image"
	@echo "  build-processor Build event processor image"
	@echo ""
	@echo "Testing:"
	@echo "  test            Run complete test suite"
	@echo "  health          Check service health"
	@echo "  status          Show service status"
	@echo ""
	@echo "Kafka:"
	@echo "  topics          List Kafka topics"
	@echo "  create-topic    Create events topic"
	@echo ""
	@echo "AWS Deployment:"
	@echo "  aws-build       Build and tag image for ECR"
	@echo "  aws-push        Push image to ECR"
	@echo "  aws-deploy      Deploy new image to ECS"
	@echo "  tf-plan         Terraform plan"
	@echo "  tf-apply        Terraform apply"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean           Stop services and remove volumes"
	@echo "  clean-all       Remove everything including images"

up:
	@echo "Starting all services..."
	@docker-compose up -d --build
	@echo "Waiting for services to be ready..."
	@sleep 10
	@echo ""
	@echo "Services started! Access points:"
	@echo "- API Service: http://localhost:5001"
	@echo "- Kafka UI: http://localhost:8080"
	@echo "- Health Check: http://localhost:5001/healthcheck"
	@echo "- Hello: http://localhost:5001/hello"
	@echo "- Current Time: http://localhost:5001/current_time?name=yourname"
	@echo ""
	@echo "Run 'make test' to verify everything is working"

down:
	@echo "Stopping all services..."
	@docker-compose down

restart: down up

logs:
	@docker-compose logs -f

logs-api:
	@docker-compose logs -f api-service

logs-processor:
	@docker-compose logs -f event-processor

logs-kafka:
	@docker-compose logs -f kafka

build:
	@echo "Building all Docker images..."
	@docker-compose build

build-api:
	@echo "Building API service image..."
	@docker build -f docker/api-service.Dockerfile -t event-processing-api .

build-processor:
	@echo "Building event processor image..."
	@docker build -f docker/event-processor.Dockerfile -t event-processing-processor .

test:
	@echo "Testing event processing system..."
	@echo ""
	@echo "1. Testing healthcheck..."
	@curl -s http://localhost:5001/healthcheck | jq . || echo "API not ready - run 'make up' first"
	@echo ""
	@echo "2. Testing hello endpoint..."
	@curl -s http://localhost:5001/hello | jq . || echo "Failed"
	@echo ""
	@echo "3. Testing current_time endpoint..."
	@curl -s "http://localhost:5001/current_time?name=TestUser" | jq . || echo "Failed"
	@echo ""
	@echo "4. Testing current_time with different name..."
	@curl -s "http://localhost:5001/current_time?name=Alice" | jq . || echo "Failed"
	@echo ""
	@echo "5. Checking recent processor logs..."
	@docker-compose logs --tail=5 event-processor
	@echo ""
	@echo "Test completed! Check logs with 'make logs-processor'"

health:
	@echo "Checking service health..."
	@echo "API Service:"
	@curl -s http://localhost:5001/healthcheck | jq . || echo " Not responding"
	@echo ""
	@echo "Service Status:"
	@docker-compose ps

status:
	@docker-compose ps

topics:
	@echo "Kafka topics:"
	@docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list

create-topic:
	@echo "Creating events topic..."
	@docker exec kafka kafka-topics --create --topic events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 --if-not-exists

clean:
	@echo "Stopping services and removing volumes..."
	@docker-compose down -v

clean-all: clean
	@echo "Removing all images..."
	@docker-compose down --rmi all -v
	@docker image prune -f

aws-build:
	@echo "Building image for AWS deployment..."
	@./scripts/build.sh

aws-push:
	@echo "Pushing image to ECR..."
	@./scripts/push.sh

aws-deploy:
	@echo "Deploying to ECS..."
	@./scripts/deploy-ecs.sh

tf-plan:
	@echo "Running Terraform plan..."
	@cd infrastructure/environments/prod && terraform init && terraform plan \
		-var="project_name=event-processing-service" \
		-var="aws_region=us-east-1"

tf-apply:
	@echo "Applying Terraform changes..."
	@./scripts/deploy.sh