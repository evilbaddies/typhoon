# Self-hosted Kubernetes assets (kubeconfig, manifests)
module "bootkube" {
  source = "git::https://github.com/evilbaddies/terraform-render-bootkube.git?ref=98ff249b6295803ccd8d189a174c4b46c0b625b5"

  cluster_name          = "${var.cluster_name}"
  api_servers           = ["${format("%s.%s", var.cluster_name, var.dns_zone)}"]
  etcd_servers          = "${digitalocean_record.etcds.*.fqdn}"
  asset_dir             = "${var.asset_dir}"
  networking            = "${var.networking}"
  network_mtu           = 1440
  pod_cidr              = "${var.pod_cidr}"
  service_cidr          = "${var.service_cidr}"
  cluster_domain_suffix = "${var.cluster_domain_suffix}"
}
