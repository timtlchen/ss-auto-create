provider "google" {
  region = "${var.region}"
  project = "${var.project_id}"
  credentials = "${file(var.account_file_path)}"
}


resource "google_compute_firewall" "${var.project_tag}-firewall-rule" {
  name    = "${var.project_tag}-allow-port"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["${var.port_range}"]
  }
}


resource "google_compute_instance" "${var.project_tag}" {
  count = ${var.vm_count}
  name = "${var.project_tag}-${var.vm_count}"
  machine_type = "${var.machine_type}"
  zone = "${var.region_zone}"

  disk {
    image = "${var.boot_disk_img}"
  }
  network_interface {
    network = "default"
    access_config {
        # Ephemeral
    }
  }
  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }

}