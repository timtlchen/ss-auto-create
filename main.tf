provider "google" {
  region = "${var.region}"
  project = "${var.project_id}"
  credentials = "${file(var.account_file_path)}"
}


resource "google_compute_firewall" "ss-firewall-rule" {
  name    = "${var.project_tag}-allow-port"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["${var.port_range}"]
  }
}


resource "google_compute_instance" "ss-instance" {
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


resource "google_compute_instance_group" "ss-instance-group" {
  name        = "${var.project_tag}-instance-group"

  instances = [
    "${google_compute_instance.ss-instance.*.self_link}",
  ]
  
   named_port {
    name = "ssport"
    port = "${var.ss_server_port}"
  }

  zone = "${var.region_zone}"
}

resource "google_compute_health_check" "ss-health-check" {
  name = "${var.project_tag}-health-check"
  tcp_health_check {
    port = "${var.ss_server_port}"
  }
  timeout_sec         = 5
  check_interval_sec  = 10
  unhealthy_threshold = 3
  healthy_threshold   = 2
}


resource "google_compute_forwarding_rule" "ss-forwarding-rule" {
  name       = "${var.project_tag}-forwarding-rule"
  // if static ip is used then add this ----  ip_address = 1.1.1.1
  ip_protocol = "TCP"
  port_range = "5222-5222"
  target = "${google_compute_target_tcp_proxy.ss-target-proxy.self_link}"
}

resource "google_compute_target_tcp_proxy" "ss-target-proxy" {
  name = "${var.project_tag}-target-proxy"
  backend_service = "${google_compute_backend_service.ss-backend.self_link}"
}


resource "google_compute_backend_service" "ss-backend" {
  name        = "${var.project_tag}-backend"
  port_name   = "ssport"
  protocol    = "TCP"
  timeout_sec = 30
  enable_cdn  = false

  backend {
    group = "${google_compute_instance_group.ss-instance-group}}"
  }

  health_checks = ["${google_compute_health_check.ss-health-check.self_link}"]
}