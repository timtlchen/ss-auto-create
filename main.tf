provider "google" {
  region = "${var.region}"
  project = "${var.project_id}"
  credentials = "${file(var.account_file_path)}"
}


resource "google_compute_firewall" "auto-firewall-rule" {
  name    = "${var.project_tag}-allow-port"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["${var.port_range}"]
  }
}


resource "google_compute_instance" "auto-instance" {
  count = "${var.instance_count}"
  name = "${var.project_tag}-${count.index}"
  machine_type = "${var.machine_type}"
  zone = "${var.region_zone}"

  boot_disk {
    initialize_params {
      image = "${var.boot_disk_img}"
    }
  }
  
  network_interface {
    network = "default"
    access_config {
        # Ephemeral
    }
  }
  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

}


resource "google_compute_instance_group" "auto-instance-group" {
  name        = "${var.project_tag}-instance-group"

  instances = [
    "projects/${var.project_id}/zones/${var.region_zone}/instances/${var.project_tag}-${count.index}",
  ]
  
   named_port {
    name = "ss-server-port"
    port = "${var.ss_server_port}"
  }

  zone = "${var.region_zone}"
}