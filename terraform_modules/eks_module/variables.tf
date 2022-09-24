variable "cluster_name"{
    default = ""
}

variable "state_bucket"{
    default = ""
}

variable "state_key"{
    default = ""
}

variable "state_region"{
    default = "us-east-1"
}

variable "vpc_id"{
    default = ""
}

variable "subnet_ids"{
    type = list
    # default = ""
}

variable "ec2noderole"{
    default = ""
}

variable "eksrole"{
    default = ""
}

variable "fargatenoderole"{
    default = ""
}