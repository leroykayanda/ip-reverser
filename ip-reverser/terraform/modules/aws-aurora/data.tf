data "aws_db_cluster_snapshot" "snapshot" {
  count                          = var.creating_db ? 1 : 0
  db_cluster_identifier          = var.snapshot_cluster
  db_cluster_snapshot_identifier = var.db_cluster_snapshot_identifier
}
