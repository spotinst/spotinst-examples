region                        = "us-west-2"
spotinst_token                = ""
spotinst_account              = ""
keypair                       = ""
subnet_ids                    = [""]
security_groups               = [""]
instance_types_ondemand       = "t3a.large"
instance_types_spot           = ["r4.xlarge", "r4.2xlarge"]
instance_types_preferred_spot = ["r4.xlarge"]

# Cluster Name of ELK - Optional
ELK-CluserName = "Testing"

# Master configuration
tagName       = "Role"
tagValue      = "ES-Master"
master_subnet = ""