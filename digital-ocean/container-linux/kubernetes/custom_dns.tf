# Add a record to the domain
resource "digitalocean_record" "mail" {
  domain = "${var.dns_zone}"
  name = "mail"
  type   = "A"
  value  = "${digitalocean_droplet.mail_worker.ipv4_address}"
}

# Add a record to the domain
resource "digitalocean_record" "root" {
  count = "${var.worker_count}"

  domain = "${var.dns_zone}"
  name = "@"
  type   = "A"
  value  = "${element(digitalocean_droplet.workers.*.ipv4_address, count.index)}"
}
