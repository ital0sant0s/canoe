#!/bin/bash

set -e

PROJECT_NAME=${PROJECT_NAME:-"event-processing-service"}
AWS_REGION=${AWS_REGION:-"us-east-1"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}

echo "Pushing Docker image to ECR"
echo "============================"
echo "Project: ${PROJECT_NAME}"
echo "Image Tag: ${IMAGE_TAG}"
echo "Region: ${AWS_REGION}"
echo ""

echo "Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.${AWS_REGION}.amazonaws.com

echo ""
echo "Getting ECR repository URL..."
ECR_REPO_URL=$(aws ecr describe-repositories --repository-names ${PROJECT_NAME}-api-service --region ${AWS_REGION} --query 'repositories[0].repositoryUri' --output text 2>/dev/null || echo "")

if [ -z "$ECR_REPO_URL" ]; then
    echo "Error: ECR repository not found for ${PROJECT_NAME}-api-service"
    echo "Please deploy infrastructure first using: make tf-apply"
    exit 1
fi

echo "ECR Repository URL: ${ECR_REPO_URL}"
echo ""

echo "Pushing image to ECR: ${ECR_REPO_URL}:${IMAGE_TAG}"
docker push ${ECR_REPO_URL}:${IMAGE_TAG}

echo ""
echo "Image pushed successfully!"
echo "Repository: ${ECR_REPO_URL}"
echo "Tag: ${IMAGE_TAG}"
echo ""
echo "Next step: Run 'make aws-deploy' to deploy to ECS"