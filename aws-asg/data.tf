data "terraform_remote_state" "vpc_remote_data" {
  backend = "s3"
  config = {
    bucket  = "myterraform-bucket-state-choi1-t"
    key     = "${var.name}/vpc/terraform.tfstate"
    profile = "terraform_user"
    region  = "ap-northeast-2"
  }
}

data "terraform_remote_state" "app1_remote_data" {
  backend = "s3"
  config = {
    bucket  = "myterraform-bucket-state-choi1-t"
    key     = "${var.name}/app1/terraform.tfstate"
    profile = "terraform_user"
    region  = "ap-northeast-2"
  }
}

data "terraform_remote_state" "rds_remote_data" {
  backend = "s3"
  config = {
    bucket  = "myterraform-bucket-state-choi1-t"
    key     = "${var.name}/rds/terraform.tfstate"
    profile = "terraform_user"
    region  = "ap-northeast-2"
  }
}

data "terraform_remote_state" "alb_remote_data" {
  backend = "s3"
  config = {
    bucket  = "myterraform-bucket-state-choi1-t"
    key     = "${var.name}/alb/terraform.tfstate" # (Update)
    profile = "terraform_user"
    region  = "ap-northeast-2"
  }
}