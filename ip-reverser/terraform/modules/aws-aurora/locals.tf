locals {
  snapshot_identifier = var.creating_db ? data.aws_db_cluster_snapshot.snapshot[0].id : null
}
