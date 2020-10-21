# terraform-aci-demo

This terraform demo is used to instantiate ACI logical constructs and bind the created EPGs to an existing VMM domain

## Components

### aci_terraform_demo.tf

* Terraform File to Create Demo

### terraform.tfvars

* Variable File containing APIC URL, Tenant Name, and VMM Domain Information

### ENVEXAMPLE

* Example .env file to pull demo username and password from 1password vault

* Usage:

  ```shell
  cp ENVEXAMPLE .env
  ```

## Requirements

Tested with:

* Terraform v0.13.4
* provider registry.terraform.io/ciscodevnet/aci v0.4.1

## Contributors

* Nick Thompson (@nsthompson)
