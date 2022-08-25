resource "oci_core_instance" "root_server" {
  availability_domain = oci_core_subnet.root_server.availability_domain
  compartment_id      = data.oci_identity_compartment.default.id
  display_name        = "root-server-${terraform.workspace}"
  shape               = "VM.Standard.A1.Flex"

  create_vnic_details {
    assign_public_ip = false
    display_name     = "eth01"
    hostname_label   = "root-server"
    nsg_ids          = [oci_core_network_security_group.root_server.id]
    subnet_id        = oci_core_subnet.root_server.id
  }

  metadata = {
    ssh_authorized_keys = <<EOT
%{for key, val in var.ssh_public_keys~}
${val}
%{endfor~}
EOT
    user_data           = data.cloudinit_config.root_server.rendered
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_jammy_arm.images.0.id
    boot_volume_size_in_gbs = 100
  }

  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  #    lifecycle {
  #      ignore_changes = [metadata["user_data"]]
  #    }
}

resource "oci_core_public_ip" "root_server" {
  compartment_id = data.oci_identity_compartment.default.id
  display_name   = "root-server-${terraform.workspace}"
  lifetime       = "RESERVED"
  private_ip_id  = data.oci_core_private_ips.root_server.private_ips[0]["id"]
}

resource "oci_identity_dynamic_group" "backup" {
  depends_on     = [oci_core_instance.root_server]
  compartment_id = data.oci_identity_compartment.default.id
  description    = "root-server-backup-dyn-group"
  matching_rule  = join("", ["ANY { instance.id = '", oci_core_instance.root_server.id, "' }"])
  name           = "root-server-backup-dyn-group"
}

resource "oci_identity_policy" "backup_policy" {
  depends_on     = [oci_identity_dynamic_group.backup]
  compartment_id = data.oci_identity_compartment.default.id
  description    = "root-server-backup-policy"
  name           = "root-server-backup-policy"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.backup.name} to manage buckets in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.backup.name} to manage objects in tenancy",
    format("Allow service objectstorage-%s to manage object-family in tenancy", var.region)
  ]
}

resource "oci_objectstorage_bucket" "bucket" {
  compartment_id = data.oci_identity_compartment.default.id
  name           = "root-server-backup"
  namespace      = data.oci_objectstorage_namespace.root_server.namespace
  access_type    = "NoPublicAccess"
}

data "oci_objectstorage_namespace" "root_server" {
  compartment_id = data.oci_identity_compartment.default.id
}

data "oci_core_vnic_attachments" "root_server" {
  compartment_id      = data.oci_identity_compartment.default.id
  availability_domain = local.availability_domain
  instance_id         = oci_core_instance.root_server.id
}

data "oci_core_vnic" "root_server" {
  vnic_id = data.oci_core_vnic_attachments.root_server.vnic_attachments[0]["vnic_id"]
}

data "oci_core_private_ips" "root_server" {
  vnic_id = data.oci_core_vnic.root_server.id
}

data "oci_identity_compartment" "default" {
  id = var.tenancy_ocid
}

data "oci_identity_availability_domains" "root_server" {
  compartment_id = data.oci_identity_compartment.default.id
}

resource "oci_core_vcn" "root_server" {
  dns_label      = "rootserver"
  cidr_block     = var.vpc_cidr_block
  compartment_id = data.oci_identity_compartment.default.id
  display_name   = "root-server-${terraform.workspace}"
}

resource "oci_core_internet_gateway" "root_server" {
  compartment_id = data.oci_identity_compartment.default.id
  vcn_id         = oci_core_vcn.root_server.id
  display_name   = "root-server-${terraform.workspace}"
  enabled        = "true"
}

resource "oci_core_default_route_table" "root_server" {
  manage_default_resource_id = oci_core_vcn.root_server.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.root_server.id
  }
}

resource "oci_core_network_security_group" "root_server" {
  compartment_id = data.oci_identity_compartment.default.id
  vcn_id         = oci_core_vcn.root_server.id
  display_name   = "root-server-nsg"
  freeform_tags  = { "Service" = "root-server" }
}

resource "oci_core_network_security_group_security_rule" "root_server_egress_rule" {
  network_security_group_id = oci_core_network_security_group.root_server.id
  direction                 = "EGRESS"
  protocol                  = "all"
  description               = "Egress All"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "root_server_ingress_ssh_rule" {
  network_security_group_id = oci_core_network_security_group.root_server.id
  direction                 = "INGRESS"
  protocol                  = "6"
  description               = "ssh-ingress"
  source                    = local.myip
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      max = 22
      min = 22
    }
  }

  lifecycle {
    ignore_changes = [source]
  }
}

resource "oci_core_network_security_group_security_rule" "root_server_ingress_443_rule" {
  network_security_group_id = oci_core_network_security_group.root_server.id
  direction                 = "INGRESS"
  protocol                  = "6"
  description               = "443-ingress"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      max = 443
      min = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "root_server_ingress_80_rule" {
  network_security_group_id = oci_core_network_security_group.root_server.id
  direction                 = "INGRESS"
  protocol                  = "6"
  description               = "80-ingress"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      max = 80
      min = 80
    }
  }
}

resource "oci_core_security_list" "root_server" {
  compartment_id = data.oci_identity_compartment.default.id
  vcn_id         = oci_core_vcn.root_server.id
  display_name   = "root-server-${terraform.workspace}"
}

resource "oci_core_subnet" "root_server" {
  availability_domain        = local.availability_domain
  cidr_block                 = cidrsubnet(var.vpc_cidr_block, 8, 0)
  display_name               = "root-server-${terraform.workspace}"
  prohibit_public_ip_on_vnic = false
  dns_label                  = "rootserver"
  compartment_id             = data.oci_identity_compartment.default.id
  vcn_id                     = oci_core_vcn.root_server.id
  route_table_id             = oci_core_default_route_table.root_server.id
  security_list_ids          = [oci_core_security_list.root_server.id]
  dhcp_options_id            = oci_core_vcn.root_server.default_dhcp_options_id
}

data "oci_core_images" "ubuntu_jammy" {
  compartment_id   = data.oci_identity_compartment.default.id
  operating_system = "Canonical Ubuntu"
  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-22.04-([\\.0-9-]+)$"]
    regex  = true
  }
}

data "oci_core_images" "ubuntu_jammy_arm" {
  compartment_id   = data.oci_identity_compartment.default.id
  operating_system = "Canonical Ubuntu"
  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-22.04-aarch64-([\\.0-9-]+)$"]
    regex  = true
  }
}

data "cloudinit_config" "root_server" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config

package_update: true
package_upgrade: true
write_files:
  - encoding: b64
    content: "${local.db_backup_script}"
    path: /etc/cron.weekly/bmlt-db-backup
    permissions: '0755'
  - encoding: b64
    content: "${local.apache_conf}"
    path: /etc/apache2/sites-available/${var.domain}.conf
    permissions: '0644'
packages:
  - apt-transport-https
  - ca-certificates
  - apache2
  - php
  - php-curl
  - php-dom
  - php-mbstring
  - php-mysql
  - php-gd
  - php-xml
  - php-zip
  - mysql-client
  - mysql-server
  - libapache2-mod-php
  - unzip
  - certbot
  - python3-certbot-apache
  - python3-pip
  - jq
EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<BOF
#!/bin/bash


pip3 install oci-cli


# disable firewall
ufw disable
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F


# configure apache
mkdir /var/www/${var.domain}
chown -R $USER:$USER /var/www/${var.domain}
chmod -R 755 /var/www/${var.domain}
sed -i 's/^\tOptions Indexes FollowSymLinks/\tOptions FollowSymLinks/' /etc/apache2/apache2.conf
a2ensite ${var.domain}.conf
a2dissite 000-default.conf
a2enmod rewrite
systemctl restart apache2


# configure mysql
systemctl start mysql.service
# secure
mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';"
mysql_secure_installation --password=password --use-default
mysql --user=root --password=password --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH auth_socket;"
mysql --execute="UNINSTALL COMPONENT 'file://component_validate_password';"
# root server db
mysql --execute="CREATE DATABASE bmlt;"
mysql --execute="CREATE USER '${var.root_server_mysql_username}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${var.root_server_mysql_password}';"
mysql --execute="GRANT ALL PRIVILEGES ON bmlt.* TO '${var.root_server_mysql_username}'@'localhost';"
# yap db
mysql --execute="CREATE DATABASE yap;"
mysql --execute="CREATE USER '${var.yap_mysql_username}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${var.yap_mysql_password}';"
mysql --execute="GRANT ALL PRIVILEGES ON yap.* TO '${var.yap_mysql_username}'@'localhost';"
# flush
mysql --execute="FLUSH PRIVILEGES;"

# install root server
wget https://s3.amazonaws.com/archives.bmlt.app/bmlt-root-server/bmlt-root-server-build1975-3a8113b086b799cddf25c5090407ff16e4b07d85.zip -O bmlt-root-server.zip
unzip bmlt-root-server.zip
rm -f bmlt-root-server.zip
mv main_server /var/www/${var.domain}/main_server


# install yap
wget https://s3.amazonaws.com/archives.bmlt.app/yap/yap-125-4aeb4ca6fbba551fb7b1b5e5f605e1551e1e0a7d.zip -O yap.zip
unzip yap.zip
rm -f yap.zip
mv yap-125-4aeb4ca6fbba551fb7b1b5e5f605e1551e1e0a7d /var/www/${var.domain}/zonal-yap


chown -R www-data: /var/www/${var.domain}

BOF
  }
}

data "http" "ip" {
  url = "https://ifconfig.me/all.json"

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  myip                = "${jsondecode(data.http.ip.response_body).ip_addr}/32"
  availability_domain = [for i in data.oci_identity_availability_domains.root_server.availability_domains : i if length(regexall("US-ASHBURN-AD-3", i.name)) > 0][0].name
  db_backup_script    = base64encode(templatefile("${path.root}/templates/bmlt-db-backup.tpl", { bucket = oci_objectstorage_bucket.bucket.name }))
  apache_conf         = base64encode(templatefile("${path.root}/templates/apache.conf.tpl", { domain = var.domain }))
}
