module "msk_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.cluster_name}-sg"
  description = "Security group for MSK cluster"
  vpc_id      = var.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 9092
      to_port                  = 9092
      protocol                 = "tcp"
      source_security_group_id = var.ecs_security_group_id
    },
    {
      from_port                = 9094
      to_port                  = 9094
      protocol                 = "tcp"
      source_security_group_id = var.ecs_security_group_id
    },
    {
      from_port                = 9092
      to_port                  = 9092
      protocol                 = "tcp"
      source_security_group_id = var.lambda_security_group_id
    },
    {
      from_port                = 9094
      to_port                  = 9094
      protocol                 = "tcp"
      source_security_group_id = var.lambda_security_group_id
    }
  ]

  egress_rules = ["all-all"]

  tags = var.tags
}

resource "aws_msk_configuration" "main" {
  kafka_versions = [var.kafka_version]
  name           = var.cluster_name

  server_properties = var.server_properties

  description = "MSK configuration for ${var.cluster_name}"
}

module "msk" {
  source  = "terraform-aws-modules/msk-kafka-cluster/aws"
  version = "~> 2.0"

  name                   = var.cluster_name
  kafka_version          = var.kafka_version
  number_of_broker_nodes = length(var.subnet_ids)

  broker_node_client_subnets  = var.subnet_ids
  broker_node_instance_type   = var.instance_type
  broker_node_security_groups = [module.msk_sg.security_group_id]

  broker_node_storage_info = {
    ebs_storage_info = {
      volume_size = var.ebs_volume_size
    }
  }

  encryption_in_transit_client_broker = var.encryption_in_transit
  encryption_in_transit_in_cluster    = var.encryption_in_cluster
  encryption_at_rest_kms_key_arn      = var.encryption_at_rest_kms_key_id

  configuration_name     = aws_msk_configuration.main.name
  configuration_revision = aws_msk_configuration.main.latest_revision

  cloudwatch_logs_enabled = var.cloudwatch_logs_enabled
  create_cloudwatch_log_group = var.cloudwatch_logs_enabled
  cloudwatch_log_group_name = var.cloudwatch_logs_enabled ? "/aws/msk/${var.cluster_name}" : null
  cloudwatch_log_group_retention_in_days = var.log_retention_days

  tags = var.tags
}