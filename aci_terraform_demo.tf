# Define Vars Loaded via .tfvars and .env
variable "apic_username" {}
variable "apic_password" {}
variable "apic_url" {}
variable "tenant_name" {}
variable "vmm_domain_name" {}

# Configure ACI Provider
provider "aci" {
    username    = var.apic_username
    password    = var.apic_password
    url         = var.apic_url
    insecure    = true
}

# Import Existing VMM Domain
data "aci_vmm_domain" "terraform_demo_vmmdom" {
    provider_profile_dn     = "uni/vmmp-VMware"
    name                    = var.vmm_domain_name
}

# Create ACI Tenant
resource "aci_tenant" "terraform_demo" {
    name        = var.tenant_name
    description = "ACI Tenant for Terraform Demo"
}

# Create VRF
resource "aci_vrf" "terraform_demo_vrf" {
    tenant_dn   = aci_tenant.terraform_demo.id
    name        = "${aci_tenant.terraform_demo.name}_vrf"
}

# Create Bridge Domain
resource "aci_bridge_domain" "terraform_demo_bd" {
    tenant_dn           = aci_tenant.terraform_demo.id
    relation_fv_rs_ctx  = aci_vrf.terraform_demo_vrf.id
    name                = "${aci_tenant.terraform_demo.name}_bd"
}

# Create BD Subnet
resource "aci_subnet" "terraform_demo_subnet_1" {
    parent_dn    = aci_bridge_domain.terraform_demo_bd.id
    ip                  = "10.10.10.1/24"
    scope               = "private"
}

resource "aci_subnet" "terraform_demo_subnet_2" {
    parent_dn    = aci_bridge_domain.terraform_demo_bd.id
    ip                  = "10.10.20.1/24"
    scope               = "private"
}

# Create Application Profile
resource "aci_application_profile" "terraform_demo_app" {
    tenant_dn       = aci_tenant.terraform_demo.id
    name            = "${aci_tenant.terraform_demo.name}_app"
}

# Create EPGs
resource "aci_application_epg" "terraform_demo_epg" {
    count                       = 2
    application_profile_dn      = aci_application_profile.terraform_demo_app.id
    name                        = "${aci_tenant.terraform_demo.name}_epg_${count.index}"
    relation_fv_rs_bd           = aci_bridge_domain.terraform_demo_bd.id
    description                 = "${aci_tenant.terraform_demo.name}_epg_${count.index} End Point Group"
    # Consume EPG Contract
    relation_fv_rs_cons         = [
        aci_contract.terraform_demo_contract.id
    ]
    # Provide EPG Contract
    relation_fv_rs_prov         = [
        aci_contract.terraform_demo_contract.id
    ]
}

# Bind EPGs to VMM Domain
resource "aci_epg_to_domain" "terraform_demo_epg_vmm" {
    count                       = 2
    application_epg_dn          = aci_application_epg.terraform_demo_epg.*.id[count.index]
    tdn                         = data.aci_vmm_domain.terraform_demo_vmmdom.id
}

# Create Contract
resource "aci_contract" "terraform_demo_contract" {
    tenant_dn       = aci_tenant.terraform_demo.id
    name            = "${aci_tenant.terraform_demo.name}_contract"
    description     = "${aci_tenant.terraform_demo.name} Demo Contract"
}

# Create Contract Subject
resource "aci_contract_subject" "terraform_demo_subject" {
    contract_dn                     = aci_contract.terraform_demo_contract.id
    name                            = "${aci_tenant.terraform_demo.name}_any_to_any"
    description                     = "Permit Any to Any"
    relation_vz_rs_subj_filt_att    = [
        aci_filter.terraform_demo_filter.id
    ]
}

# Create Contract Filter
resource "aci_filter" "terraform_demo_filter" {
    tenant_dn       = aci_tenant.terraform_demo.id
    description     = "Terraform Demo Filter"
    name            = "${aci_tenant.terraform_demo.name}_filter"
}

# Create Filter Entry
resource "aci_filter_entry" "terraform_demo_filter_entry" {
    filter_dn       = aci_filter.terraform_demo_filter.id
    description     = "Terraform Demo Filter - Permit Any"
    name            = "any_ip_unspecified"
    ether_t         = "ip"
    prot            = "unspecified"
}