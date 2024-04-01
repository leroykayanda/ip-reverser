resource "aws_kms_key" "kms_key" {
  description = "Encrypts the ${var.env}-${var.microservice_name} db"

  deletion_window_in_days = 7
}

resource "aws_db_subnet_group" "subnet_group" {
  name        = "${var.env}-${var.microservice_name}"
  subnet_ids  = var.db_subnets
  description = "Private subnets for the db"
}

resource "random_string" "random" {
  length  = 5
  special = false
  upper   = false
}

resource "aws_rds_cluster_parameter_group" "db_parameter_group" {
  name   = "${var.env}-${var.microservice_name}-cluster"
  family = var.parameter_group_family
}

resource "aws_db_parameter_group" "db_parameter_group" {
  name   = "${var.env}-${var.microservice_name}-instance"
  family = var.parameter_group_family
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier              = "${var.env}-${var.microservice_name}"
  apply_immediately               = true
  engine                          = var.db_engine
  engine_version                  = var.engine_version
  engine_mode                     = "provisioned"
  availability_zones              = var.availability_zones
  master_username                 = var.master_username
  master_password                 = var.master_password
  backup_retention_period         = var.backup_retention_period
  db_subnet_group_name            = aws_db_subnet_group.subnet_group.name
  deletion_protection             = true
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.kms_key.arn
  port                            = var.port
  preferred_maintenance_window    = var.preferred_maintenance_window
  preferred_backup_window         = var.preferred_backup_window
  skip_final_snapshot             = false
  vpc_security_group_ids          = [var.security_group_id]
  final_snapshot_identifier       = "${var.env}-${var.microservice_name}"
  database_name                   = var.database_name
  snapshot_identifier             = local.snapshot_identifier
  allow_major_version_upgrade     = true
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.db_parameter_group.name
  storage_type                    = "aurora-iopt1"

  lifecycle {
    ignore_changes = [
      availability_zones, snapshot_identifier
    ]
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {

  lifecycle {
    prevent_destroy = true
  }

  instance_class                        = var.db_cluster_instance_class
  count                                 = var.db_instance_count
  identifier                            = "${var.microservice_name}-${count.index}-${random_string.random.id}"
  cluster_identifier                    = aws_rds_cluster.aurora.id
  engine                                = aws_rds_cluster.aurora.engine
  engine_version                        = aws_rds_cluster.aurora.engine_version
  publicly_accessible                   = var.publicly_accessible
  db_subnet_group_name                  = aws_rds_cluster.aurora.db_subnet_group_name
  apply_immediately                     = true
  promotion_tier                        = 2
  preferred_maintenance_window          = aws_rds_cluster.aurora.preferred_maintenance_window
  auto_minor_version_upgrade            = true
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_enabled ? aws_kms_key.kms_key.arn : null
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null
  db_parameter_group_name               = aws_db_parameter_group.db_parameter_group.name

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_CPUUtilization" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-High-CPU"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "90"
  alarm_description   = "This alarm monitors for high database CPU"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora.cluster_identifier
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_FreeableMemory" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-Low-Memory"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Minimum"
  threshold           = "500000000"
  alarm_description   = "This alarm monitors for low database memory"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora.cluster_identifier
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_CPUCreditBalance" {
  count               = var.create_cpu_credit_alarm == "yes" ? 1 : 0
  alarm_name          = "${var.env}-${var.microservice_name}-DB-Low-CPUCreditBalance"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "This alarm monitors for low CPUCreditBalance"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora.cluster_identifier
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_ReadLatency" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-High-ReadLatency"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "This alarm monitors for high read latency"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora.cluster_identifier
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_WriteLatency" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-High-WriteLatency"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "This alarm monitors for high write latency"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora.cluster_identifier
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_DiskQueueDepth" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-High-DiskQueueDepth"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DiskQueueDepth"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "200"
  alarm_description   = "This alarm monitors for high write disk queue depth"
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora.cluster_identifier
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_DBLoad" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-High-DBLoad"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DBLoad"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.dbload_threshold
  alarm_description   = "This alarm monitors for high DB Load. Check RDS performace insights for details."
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  dimensions = {
    DBInstanceIdentifier = aws_rds_cluster_instance.cluster_instances[0].id
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_FreeLocalStorage" {
  alarm_name          = "${var.env}-${var.microservice_name}-DB-Low-FreeLocalStorage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = var.local_storage_threshold
  alarm_description   = "This alarm monitors for low FreeLocalStorage on a DB instance."
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  datapoints_to_alarm = "1"
  treat_missing_data  = "ignore"

  metric_query {
    id          = "e1"
    expression  = "m1/1000000000"
    label       = "FreeLocalStorage"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "FreeLocalStorage"
      namespace   = "AWS/RDS"
      period      = 300
      stat        = "Minimum"

      dimensions = {
        DBInstanceIdentifier = aws_rds_cluster_instance.cluster_instances[0].id
      }
    }
  }

  tags = {
    Environment = var.env
    Team        = var.team
  }
}

resource "aws_cloudwatch_dashboard" "dash" {
  dashboard_name = "${var.env}-${var.microservice_name}-DB"

  dashboard_body = jsonencode(
    {
      "widgets" : [
        {
          "type" : "metric",
          "x" : 0,
          "y" : 0,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", aws_rds_cluster.aurora.cluster_identifier, { "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "stat" : "Maximum",
            "period" : 300,
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "cpu",
                  "value" : 90
                }
              ]
            }
          }
        },
        {
          "type" : "metric",
          "x" : 6,
          "y" : 0,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              [{ "expression" : "m1/1000000000", "label" : "FreeableMemory", "id" : "e1", "region" : "${var.region}" }],
              ["AWS/RDS", "FreeableMemory", "DBClusterIdentifier", aws_rds_cluster.aurora.cluster_identifier, { "id" : "m1", "visible" : false, "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "mem Gb",
                  "value" : 1
                }
              ]
            },
            "stat" : "Minimum",
            "period" : 300,
            "title" : "FreeableMemory",
            "yAxis" : {
              "left" : {
                "showUnits" : false
              }
            }
          }
        },
        {
          "type" : "metric",
          "x" : 18,
          "y" : 6,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/RDS", "ReadLatency", "DBClusterIdentifier", aws_rds_cluster.aurora.cluster_identifier],
              [".", "WriteLatency", ".", "."]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "stat" : "Maximum",
            "period" : 300
          }
        },
        {
          "type" : "metric",
          "x" : 0,
          "y" : 18,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/RDS", "VolumeBytesUsed", "DBClusterIdentifier", aws_rds_cluster.aurora.cluster_identifier, { "region" : "${var.region}", "label" : "VolumeBytesUsed" }],
              [".", "BackupRetentionPeriodStorageUsed", ".", "prod-finflow", { "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "stat" : "Maximum",
            "period" : 300,
            "yAxis" : {
              "left" : {
                "showUnits" : false
              }
            }
          }
        },
        {
          "type" : "metric",
          "x" : 12,
          "y" : 12,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              [{ "expression" : "(m1+m2)/300", "label" : "IOPs", "id" : "e1", "region" : "${var.region}" }],
              ["AWS/RDS", "VolumeReadIOPs", "DBClusterIdentifier", aws_rds_cluster.aurora.cluster_identifier, { "id" : "m1", "visible" : false, "region" : "${var.region}" }],
              [".", "VolumeWriteIOPs", ".", ".", { "id" : "m2", "visible" : false, "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "stat" : "Maximum",
            "period" : 300,
            "title" : "IOPs",
            "yAxis" : {
              "left" : {
                "showUnits" : false
              }
            }
          }
        },
        {
          "type" : "metric",
          "x" : 0,
          "y" : 6,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "view" : "timeSeries",
            "stacked" : true,
            "metrics" : [
              ["AWS/RDS", "BufferCacheHitRatio", "DBClusterIdentifier", aws_rds_cluster.aurora.cluster_identifier]
            ],
            "region" : "${var.region}",
            "stat" : "Minimum",
          }
        },
        {
          "type" : "metric",
          "x" : 12,
          "y" : 6,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "view" : "timeSeries",
            "stacked" : true,
            "metrics" : [
              ["AWS/RDS", "CommitThroughput", "DBClusterIdentifier", aws_rds_cluster.aurora.cluster_identifier]
            ],
            "region" : "${var.region}",
            "stat" : "Maximum",
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "commits/sec",
                  "value" : 500
                }
              ]
            }
          }
        },
        {
          "type" : "metric",
          "x" : 0,
          "y" : 12,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", aws_rds_cluster.aurora.cluster_identifier, { "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "connections",
                  "value" : 100
                }
              ]
            },
            "period" : 300,
            "stat" : "Sum"
          }
        },
        {
          "type" : "metric",
          "x" : 6,
          "y" : 12,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              ["AWS/RDS", "DBLoad", "DBInstanceIdentifier", aws_rds_cluster_instance.cluster_instances[0].id, { "region" : "${var.region}" }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "stat" : "Average",
            "period" : 60,
            "title" : "DBLoad",
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "load",
                  "value" : "${var.dbload_threshold}"
                }
              ]
            },
            "yAxis" : {
              "left" : {
                "showUnits" : false
              }
            }
          }
        },
        {
          "type" : "metric",
          "x" : 6,
          "y" : 6,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "view" : "timeSeries",
            "stacked" : true,
            "metrics" : [
              ["AWS/RDS", "Deadlocks", "DBClusterIdentifier", aws_rds_cluster.aurora.cluster_identifier]
            ],
            "region" : "${var.region}",
            "stat" : "Maximum",
          }
        },
        {
          "type" : "metric",
          "x" : 18,
          "y" : 0,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "view" : "timeSeries",
            "stacked" : true,
            "metrics" : [
              ["AWS/RDS", "DiskQueueDepth", "DBClusterIdentifier", aws_rds_cluster.aurora.cluster_identifier]
            ],
            "region" : "${var.region}",
            "stat" : "Average",
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "queue_depth",
                  "value" : 200
                }
              ]
            }
          }
        },
        {
          "type" : "metric",
          "x" : 18,
          "y" : 12,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "metrics" : [
              [{ "expression" : "m1/1000000000", "label" : "FreeLocalStorage", "id" : "e1", "region" : "${var.region}" }],
              ["AWS/RDS", "FreeLocalStorage", "DBInstanceIdentifier", aws_rds_cluster_instance.cluster_instances[0].id, { "region" : "${var.region}", "id" : "m1", "visible" : false }]
            ],
            "view" : "timeSeries",
            "stacked" : true,
            "region" : "${var.region}",
            "period" : 300,
            "stat" : "Minimum",
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "free_local_storage Gb",
                  "value" : 10
                }
              ]
            },
            "title" : "FreeLocalStorage",
            "yAxis" : {
              "left" : {
                "showUnits" : false
              }
            }
          }
        },
        {
          "type" : "metric",
          "x" : 12,
          "y" : 0,
          "width" : 6,
          "height" : 6,
          "properties" : {
            "view" : "timeSeries",
            "stacked" : true,
            "metrics" : [
              ["AWS/RDS", "SwapUsage", "DBClusterIdentifier", aws_rds_cluster.aurora.cluster_identifier]
            ],
            "region" : "${var.region}",
            "stat" : "Maximum",
          }
        }
      ]
    }
  )
}




