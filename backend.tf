terraform {
  backend "s3" {
    bucket = "0me-terraform"
    key    = "minecraft.tfstate"
    region = "ap-northeast-1"
  }
}