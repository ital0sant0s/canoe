#!/bin/bash

set -e

PROJECT_NAME=${PROJECT_NAME:-"event-processing-service"}
AWS_REGION=${AWS_REGION:-"us-east-1"}

echo "Deploying Event Processing Service Infrastructure"
echo "================================================"
echo "Project: ${PROJECT_NAME}"
echo "Region: ${AWS_REGION}"
echo ""

DEPLOY_DIR="infrastructure/environments/prod"

if [ ! -d "$DEPLOY_DIR" ]; then
    echo "Error: Infrastructure directory '$DEPLOY_DIR' does not exist"
    exit 1
fi

echo "Deployment directory: $DEPLOY_DIR"
echo ""

cd "$DEPLOY_DIR"

echo "Initializing Terraform..."
terraform init

echo ""
echo "Validating Terraform configuration..."
terraform validate

echo ""
echo "Planning deployment..."

if [ ! -f "terraform.tfvars" ]; then
    echo "Warning: terraform.tfvars not found"
    echo "Please copy terraform.tfvars.example to terraform.tfvars and configure it"
    echo ""
    read -p "Continue with default values? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 1
    fi
fi

terraform plan \
    -var="project_name=${PROJECT_NAME}" \
    -var="aws_region=${AWS_REGION}"

echo ""
read -p "Do you want to apply these changes? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Applying Terraform changes..."

    terraform apply \
        -var="project_name=${PROJECT_NAME}" \
        -var="aws_region=${AWS_REGION}" \
        -auto-approve

    echo ""
    echo "Infrastructure deployed successfully!"
    echo ""

    echo "Getting outputs..."
    ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "N/A")
    API_ENDPOINT=$(terraform output -raw api_endpoint 2>/dev/null || echo "N/A")
    ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "N/A")

    echo "==================================="
    echo "Deployment Summary"
    echo "==================================="
    echo "ECR Repository: ${ECR_URL}"
    echo "API Endpoint: ${API_ENDPOINT}"
    echo "Load Balancer DNS: ${ALB_DNS}"
    echo ""

    if [ "$ECR_URL" != "N/A" ]; then
        echo "Next steps:"
        echo "1. Build and push Docker image: make aws-build && make aws-push"
        echo "2. Deploy application: make aws-deploy"
    fi

else
    echo "Deployment cancelled."
    exit 1
fi