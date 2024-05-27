terraform {
  backend "s3" {
    key = "aws/sap-c02/custom-vpc.tfstate"
  }
}