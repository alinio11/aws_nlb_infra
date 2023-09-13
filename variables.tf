### GENERAL
variable "region" {
  description = "AWS region used to deploy whole infrastructure"
  type        = string
  default = "eu-west-2"
}
variable "name_prefix" {
  description = "Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.)"
  type        = string
  default = "nlb-test"
}
variable "global_tags" {
  description = "Global tags configured for all provisioned resources"
  type        = map(string)
  default ={
    ManagedBy   = "terraform"
  Application = "NLB Test"
  Owner       = "NETSEC"}
}
variable "ssh_key_name" {
  description = "Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes"
  type        = string
  default = "Spoke-Bastion-Key"
}

### VPC
variable "vpcs" {
  description = <<-EOF
  A map defining VPCs with security groups and subnets.

  Following properties are available:
  - `name`: VPC name
  - `cidr`: CIDR for VPC
  - `nacls`: map of network ACLs
  - `security_groups`: map of security groups
  - `subnets`: map of subnets with properties:
     - `az`: availability zone
     - `set`: internal identifier referenced by main.tf
     - `nacl`: key of NACL (can be null)
  - `routes`: map of routes with properties:
     - `vpc_subnet` - built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
     - `next_hop_key` - must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
     - `next_hop_type` - internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint

  Example:
  ```
  vpcs = {
    example_vpc = {
      name = "example-spoke-vpc"
      cidr = "10.104.0.0/16"
      nacls = {
        trusted_path_monitoring = {
          name               = "trusted-path-monitoring"
          rules = {
            allow_inbound = {
              rule_number = 300
              egress      = false
              protocol    = "-1"
              rule_action = "allow"
              cidr_block  = "0.0.0.0/0"
              from_port   = null
              to_port     = null
            }
          }
        }
      }
      security_groups = {
        example_vm = {
          name = "example_vm"
          rules = {
            all_outbound = {
              description = "Permit All traffic outbound"
              type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
              cidr_blocks = ["0.0.0.0/0"]
            }
          }
        }
      }
      subnets = {
        "10.104.0.0/24"   = { az = "eu-central-1a", set = "vm", nacl = null }
        "10.104.128.0/24" = { az = "eu-central-1b", set = "vm", nacl = null }
      }
      routes = {
        vm_default = {
          vpc_subnet    = "app1_vpc-app1_vm"
          to_cidr       = "0.0.0.0/0"
          next_hop_key  = "app1"
          next_hop_type = "transit_gateway_attachment"
        }
      }
    }
  }
  ```
  EOF

  type = map(object({
    name  = string
    cidr  = string
    nacls = map(object({
      name  = string
      rules = map(object({
        rule_number = number
        egress      = bool
        protocol    = string
        rule_action = string
        cidr_block  = string
        from_port   = string
        to_port     = string
      }))
    }))
    security_groups = any
    subnets         = map(object({
      az   = string
      set  = string
      nacl = string
    }))
    routes = map(object({
      vpc_subnet    = string
      to_cidr       = string
      next_hop_key  = string
      next_hop_type = string
    }))
  }))
  default = {

    nlb_vpc = {
      name            = "nlb_vpc"
      cidr            = "10.150.0.0/16"
      nacls           = {}
      security_groups = {

        vmseries_public = {
          name  = "vmseries_public"
          rules = {
            all_outbound = {
              description = "Permit All traffic outbound"
              type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
              cidr_blocks = ["0.0.0.0/0"]
            }
            https = {
              description = "Permit HTTPS"
              type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
              cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
            }
            ssh = {
              description = "Permit SSH"
              type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
              cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
            }

          }
        },
        vmseries_private = {
            name  = "vmseries_private"
            rules = {
              all_outbound = {
                description = "Permit All traffic outbound"
                type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
              }
              ssh = {
                description = "Permit SSH"
                type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"]
                # TODO: update here (replace 0.0.0.0/0 by your IP range)
              }
              https = {
                description = "Permit HTTPS"
                type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"]
                # TODO: update here (replace 0.0.0.0/0 by your IP range)
              }
              http = {
                description = "Permit HTTP"
                type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"]
                # TODO: update here (replace 0.0.0.0/0 by your IP range)
              }
            }
        }
      }
      subnets = {
          # Do not modify value of `set=`, it is an internal identifier referenced by main.tf
          # Value of `nacl` must match key of objects stored in `nacls`
          "10.150.0.0/24"  = { az = "eu-west-2a", set = "public", nacl = null }
          "10.150.64.0/24" = { az = "eu-west-2b", set = "public", nacl = null }
          "10.150.1.0/24"  = { az = "eu-west-2a", set = "private", nacl = null }
          "10.150.65.0/24" = { az = "eu-west-2b", set = "private", nacl = null }

        }
        routes = {
          # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
          # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
          # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
          mgmt_default = {
            vpc_subnet    = "nlb_vpc-public"
            to_cidr       = "0.0.0.0/0"
            next_hop_key  = "nlb_vpc"
            next_hop_type = "internet_gateway"
          }

        }
    }

  }
}


### SPOKE VMS
variable "spoke_vms" {
  description = <<-EOF
  A map defining VMs in spoke VPCs.

  Following properties are available:
  - `az`: name of the Availability Zone
  - `vpc`: name of the VPC (needs to be one of the keys in map `vpcs`)
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character
  - `security_group`: security group assigned to ENI used by VM
  - `type`: EC2 type VM

  Example:
  ```
  spoke_vms = {
    "app1_vm01" = {
      az             = "eu-central-1a"
      vpc            = "app1_vpc"
      vpc_subnet     = "app1_vpc-app1_vm"
      security_group = "app1_vm"
      type           = "t2.micro"
    }
  }
  ```
  EOF
  default     = {

  "app1_vm01" = {
    az             = "eu-west-2a"
    vpc            = "nlb_vpc"
    vpc_subnet     = "nlb_vpc-private"
    security_group = "vmseries_private"
    type           = "t2.micro"
  },
  "app1_vm02" = {
    az             = "eu-west-2b"
    vpc            = "nlb_vpc"
    vpc_subnet     = "nlb_vpc-private"
    security_group = "vmseries_private"
    type           = "t2.micro"
  }

}

  type = map(object({
    az             = string
    vpc            = string
    vpc_subnet     = string
    security_group = string
    type           = string
  }))
}

### SPOKE LOADBALANCERS
variable "spoke_lbs" {
  description = <<-EOF
  A map defining Network Load Balancers deployed in spoke VPCs.

  Following properties are available:
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character
  - `vms`: keys of spoke VMs

  Example:
  ```
  spoke_lbs = {
    "app1-nlb" = {
      vpc_subnet = "app1_vpc-app1_lb"
      vms        = ["app1_vm01", "app1_vm02"]
    }
  }
  ```
  EOF

  type = map(object({
    vpc_subnet = string
    vms        = list(string)
  }))
  default     = {
    "app1-nlb" = {
    vpc_subnet = "nlb_vpc-private"
    vms        = ["app1_vm01", "app1_vm02"]
  }
  }
}
