provider "google" {
  project = "vpn-server-sasp"
  region  = "us-central1"
  zone    = "us-central1-a"
}

#resource "google_compute_address" "static" {
#  name = "ipv4-address"
#}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"
  tags = ["http-server", "https-server"]
  can_ip_forward = "true"

  metadata = {
    enable-oslogin: true
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
      size = 10
      type = "pd-standard"
    }
  }

  network_interface {
      # Creates a random external ephemeral address. To create static ip address uncomment the commented lines on this file.
      network = "default"
      access_config {
      }
    }

  #network_interface {
  #  # A default network is created for all GCP projects
  #  network = google_compute_network.vpc_network.self_link
  #  access_config {
  #    nat_ip = google_compute_address.static.address
  #  }
  #}
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = "true"
}
