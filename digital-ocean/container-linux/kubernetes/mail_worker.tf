# Mail worker droplet instance
resource "digitalocean_droplet" "mail_worker" {

  name   = "${var.cluster_name}-mail-worker"
  region = "${var.region}"

  image = "${var.image}"
  size  = "${var.worker_type}"

  #network
  ipv6               = true
  private_networking = true

  user_data = "${data.ct_config.worker_ign.rendered}"
  ssh_keys  = "${var.ssh_fingerprints}"

  tags = [
    "${digitalocean_tag.workers.id}",
  ]

  lifecycle {
    ignore_changes = ["volume_ids"]
  }
}