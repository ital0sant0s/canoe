#!/bin/bash

set -e

PROJECT_NAME=${PROJECT_NAME:-"event-processing-service"}
AWS_REGION=${AWS_REGION:-"us-east-1"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}

echo "Deploying to ECS"
echo "================"
echo "Project: ${PROJECT_NAME}"
echo "Image Tag: ${IMAGE_TAG}"
echo "Region: ${AWS_REGION}"
echo ""

CLUSTER_NAME="${PROJECT_NAME}-cluster"
SERVICE_NAME="${PROJECT_NAME}-api-service"

echo "Checking if ECS cluster exists..."
CLUSTER_EXISTS=$(aws ecs describe-clusters --clusters ${CLUSTER_NAME} --region ${AWS_REGION} --query 'clusters[0].status' --output text 2>/dev/null || echo "MISSING")

if [ "$CLUSTER_EXISTS" = "MISSING" ] || [ "$CLUSTER_EXISTS" = "None" ]; then
    echo "Error: ECS cluster '${CLUSTER_NAME}' not found"
    echo "Please deploy infrastructure first using: make tf-apply"
    exit 1
fi

echo "ECS cluster found: ${CLUSTER_NAME}"

echo ""
echo "Checking if ECS service exists..."
SERVICE_EXISTS=$(aws ecs describe-services --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME} --region ${AWS_REGION} --query 'services[0].status' --output text 2>/dev/null || echo "MISSING")

if [ "$SERVICE_EXISTS" = "MISSING" ] || [ "$SERVICE_EXISTS" = "None" ]; then
    echo "Error: ECS service '${SERVICE_NAME}' not found in cluster '${CLUSTER_NAME}'"
    echo "Please deploy infrastructure first using: make tf-apply"
    exit 1
fi

echo "ECS service found: ${SERVICE_NAME}"

echo ""
if [ "$IMAGE_TAG" != "latest" ]; then
    echo "Updating ECS service with image tag: ${IMAGE_TAG}"

    ECR_REPO_URL=$(aws ecr describe-repositories --repository-names ${PROJECT_NAME}-api-service --region ${AWS_REGION} --query 'repositories[0].repositoryUri' --output text 2>/dev/null || echo "")

    if [ -z "$ECR_REPO_URL" ]; then
        echo "Error: ECR repository not found for ${PROJECT_NAME}-api-service"
        exit 1
    fi

    NEW_IMAGE="${ECR_REPO_URL}:${IMAGE_TAG}"
    echo "New image: ${NEW_IMAGE}"

    CURRENT_TASK_DEF=$(aws ecs describe-services --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME} --region ${AWS_REGION} --query 'services[0].taskDefinition' --output text)
    echo "Current task definition: ${CURRENT_TASK_DEF}"

    TASK_DEF_JSON=$(aws ecs describe-task-definition --task-definition ${CURRENT_TASK_DEF} --region ${AWS_REGION} --query 'taskDefinition')

    NEW_TASK_DEF=$(echo $TASK_DEF_JSON | jq --arg image "$NEW_IMAGE" '.containerDefinitions[0].image = $image | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.placementConstraints) | del(.compatibilities) | del(.registeredAt) | del(.registeredBy)')

    echo "Registering new task definition..."
    NEW_TASK_DEF_ARN=$(echo $NEW_TASK_DEF | aws ecs register-task-definition --region ${AWS_REGION} --cli-input-json file:///dev/stdin --query 'taskDefinition.taskDefinitionArn' --output text)
    echo "New task definition: ${NEW_TASK_DEF_ARN}"

    echo "Updating ECS service with new task definition..."
    aws ecs update-service \
        --cluster ${CLUSTER_NAME} \
        --service ${SERVICE_NAME} \
        --task-definition ${NEW_TASK_DEF_ARN} \
        --region ${AWS_REGION} \
        --query 'service.serviceName' \
        --output text
else
    echo "Forcing new deployment with current image..."
    aws ecs update-service \
        --cluster ${CLUSTER_NAME} \
        --service ${SERVICE_NAME} \
        --force-new-deployment \
        --region ${AWS_REGION} \
        --query 'service.serviceName' \
        --output text
fi

echo ""
echo "Deployment initiated successfully!"
echo ""
echo "Monitor deployment:"
echo "  aws ecs describe-services --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME} --region ${AWS_REGION}"
echo ""
echo "View logs:"
echo "  aws logs tail /ecs/${PROJECT_NAME}-api-service/${PROJECT_NAME} --follow --region ${AWS_REGION}"