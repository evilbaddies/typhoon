resource "digitalocean_firewall" "mail-rules" {
  name = "${var.cluster_name}-mail"

  tags = ["mail"]

  # allow ssh, http/https ingress, and peer-to-peer traffic
  inbound_rule = [
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "25"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "587"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol    = "udp"
      port_range  = "1-65535"
      source_tags = ["${digitalocean_tag.controllers.name}", "${digitalocean_tag.workers.name}"]
    },
    {
      protocol    = "tcp"
      port_range  = "1-65535"
      source_tags = ["${digitalocean_tag.controllers.name}", "${digitalocean_tag.workers.name}"]
    },
  ]

  # allow all outbound traffic
  outbound_rule = [
    {
      protocol              = "tcp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "udp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "icmp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
  ]
}
