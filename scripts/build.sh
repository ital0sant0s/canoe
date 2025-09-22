#!/bin/bash

set -e

PROJECT_NAME=${PROJECT_NAME:-"event-processing-service"}
AWS_REGION=${AWS_REGION:-"us-east-1"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}

echo "Building Docker image for Event Processing Service"
echo "================================================="
echo "Project: ${PROJECT_NAME}"
echo "Image Tag: ${IMAGE_TAG}"
echo "Region: ${AWS_REGION}"
echo ""

echo "Building Docker image..."
docker build -f docker/api-service.Dockerfile -t ${PROJECT_NAME}-api-service:${IMAGE_TAG} .

echo "Docker image built successfully: ${PROJECT_NAME}-api-service:${IMAGE_TAG}"
echo ""

echo "Getting ECR repository URL..."
ECR_REPO_URL=$(aws ecr describe-repositories --repository-names ${PROJECT_NAME}-api-service --region ${AWS_REGION} --query 'repositories[0].repositoryUri' --output text 2>/dev/null || echo "")

if [ -z "$ECR_REPO_URL" ]; then
    echo "Warning: ECR repository not found for ${PROJECT_NAME}-api-service"
    echo "Please deploy infrastructure first using: make tf-apply"
    echo ""
    echo "Image has been built locally and tagged as: ${PROJECT_NAME}-api-service:${IMAGE_TAG}"
    exit 0
fi

echo "ECR Repository URL: $ECR_REPO_URL"
echo ""

echo "Tagging image for ECR..."
docker tag ${PROJECT_NAME}-api-service:${IMAGE_TAG} ${ECR_REPO_URL}:${IMAGE_TAG}

echo ""
echo "Image tagged successfully!"
echo "Local image: ${PROJECT_NAME}-api-service:${IMAGE_TAG}"
echo "ECR image: ${ECR_REPO_URL}:${IMAGE_TAG}"
echo ""
echo "Next step: Run 'make aws-push' to push the image to ECR"