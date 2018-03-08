# Tag to label mail worker
resource "digitalocean_tag" "mail_worker" {
  name = "${var.cluster_name}-mail-worker"
}

# Mail worker DNS record
resource "digitalocean_record" "mail_worker" {
  # DNS zone where record should be created
  domain = "${var.dns_zone}"

  name  = "${var.cluster_name}-workers"
  type  = "A"
  ttl   = 300
  value = "${digitalocean_droplet.mail_worker.ipv4_address}"
}

# Mail worker droplet instance
resource "digitalocean_droplet" "mail_worker" {

  name   = "mail.${var.dns_zone}"
  region = "${var.region}"

  image = "${var.image}"
  size  = "s-1vcpu-1gb"

  #network
  ipv6               = true
  private_networking = true

  user_data = "${data.ct_config.worker_ign.rendered}"
  ssh_keys  = "${var.ssh_fingerprints}"

  tags = [
    "${digitalocean_tag.mail_worker.id}"
  ]

  lifecycle {
    ignore_changes = ["volume_ids"]
  }
}