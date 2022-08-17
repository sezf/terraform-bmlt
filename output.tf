output "root_server_instance_info" {
  value = {
    nsg_ids    = oci_core_instance.root_server.create_vnic_details[0].nsg_ids
    public_ip  = oci_core_public_ip.root_server.ip_address
    private_ip = oci_core_instance.root_server.private_ip
  }
}
