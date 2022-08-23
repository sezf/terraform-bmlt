terraform {
  backend "s3" {
    profile        = "mvana"
    region         = "us-east-1"
    dynamodb_table = "mvana-account-terraform"
    bucket         = "mvana-account-terraform"
    key            = "state/terraform-bmlt.tfstate"
  }
}
