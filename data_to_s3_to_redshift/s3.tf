resource "aws_s3_bucket" "wofai_s3_bucket" {
  bucket = "wofai-terraform-s3-bucket"

  tags = {
    Name = "My s3 bucket"
  }
}