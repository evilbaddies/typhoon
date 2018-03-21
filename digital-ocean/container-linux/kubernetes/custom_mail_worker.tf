variable "mail_host_name" {
  type        = "string"
  description = "Mail server host name. e.g. mail1 or mail2"
}

# Add a record to the domain
resource "digitalocean_record" "mail" {
  domain = "${var.dns_zone}"
  name = "${var.mail_host_name}"
  type   = "A"
  value  = "${digitalocean_droplet.mail_worker.ipv4_address}"
}

# Tag to label mail worker
resource "digitalocean_tag" "mail_worker" {
  name = "${var.cluster_name}-mail-worker"
}

# Mail worker droplet instance
resource "digitalocean_droplet" "mail_worker" {

  name   = "${var.mail_host_name}.${var.dns_zone}"
  region = "${var.region}"

  image = "${var.image}"
  size  = "s-1vcpu-1gb"

  #network
  ipv6               = true
  private_networking = true

  user_data = "${data.ct_config.worker_ign.rendered}"
  ssh_keys  = "${var.ssh_fingerprints}"

  tags = [
#    "${digitalocean_tag.workers.id}",
    "${digitalocean_tag.mail_worker.id}",
  ]

  lifecycle {
    ignore_changes = ["volume_ids"]
  }
}

resource "digitalocean_firewall" "mail-rules" {
  name = "${var.cluster_name}-mail"

  tags = ["${var.cluster_name}-mail-worker"]

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

# Secure copy kubeconfig to all nodes. Activates kubelet.service
resource "null_resource" "mail-copy-secrets" {

  connection {
    type    = "ssh"
    host    = "${digitalocean_droplet.mail_worker.ipv4_address}"
    user    = "core"
    timeout = "15m"
  }

  provisioner "file" {
    content     = "${module.bootkube.kubeconfig}"
    destination = "$HOME/kubeconfig"
  }

  provisioner "file" {
    content     = "${module.bootkube.etcd_ca_cert}"
    destination = "$HOME/etcd-client-ca.crt"
  }

  provisioner "file" {
    content     = "${module.bootkube.etcd_client_cert}"
    destination = "$HOME/etcd-client.crt"
  }

  provisioner "file" {
    content     = "${module.bootkube.etcd_client_key}"
    destination = "$HOME/etcd-client.key"
  }

  provisioner "file" {
    content     = "${module.bootkube.etcd_server_cert}"
    destination = "$HOME/etcd-server.crt"
  }

  provisioner "file" {
    content     = "${module.bootkube.etcd_server_key}"
    destination = "$HOME/etcd-server.key"
  }

  provisioner "file" {
    content     = "${module.bootkube.etcd_peer_cert}"
    destination = "$HOME/etcd-peer.crt"
  }

  provisioner "file" {
    content     = "${module.bootkube.etcd_peer_key}"
    destination = "$HOME/etcd-peer.key"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/ssl/etcd/etcd",
      "sudo mv etcd-client* /etc/ssl/etcd/",
      "sudo cp /etc/ssl/etcd/etcd-client-ca.crt /etc/ssl/etcd/etcd/server-ca.crt",
      "sudo mv etcd-server.crt /etc/ssl/etcd/etcd/server.crt",
      "sudo mv etcd-server.key /etc/ssl/etcd/etcd/server.key",
      "sudo cp /etc/ssl/etcd/etcd-client-ca.crt /etc/ssl/etcd/etcd/peer-ca.crt",
      "sudo mv etcd-peer.crt /etc/ssl/etcd/etcd/peer.crt",
      "sudo mv etcd-peer.key /etc/ssl/etcd/etcd/peer.key",
      "sudo chown -R etcd:etcd /etc/ssl/etcd",
      "sudo chmod -R 500 /etc/ssl/etcd",
      "sudo mv /home/core/kubeconfig /etc/kubernetes/kubeconfig",
    ]
  }
}
