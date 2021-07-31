

resource "random_id" "db_name" {
  byte_length = 4
}

resource "google_sql_database_instance" "default" {
  project             = var.project_id
  name                = "${var.cluster_name}-db-${random_id.db_name.hex}"
  database_version    = "POSTGRES_12"
  region              = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    # availability_type = "REGIONAL"

    disk_size = 10
    disk_type = "PD_HDD"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.network.id
      require_ssl     = true
    }

    backup_configuration {
      enabled = false
    }

    location_preference {
      zone = var.zones[0]
    }
  }

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }

  lifecycle {
    ignore_changes = [
      settings[0].disk_size
    ]
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}
