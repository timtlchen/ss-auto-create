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
  count = 2
  name = "${var.project_tag}-${count.index}"
  machine_type = "${var.machine_type}"
  zone = "${var.region_zone}"

  boot_disk {
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