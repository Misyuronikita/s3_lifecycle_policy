provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}
//generate random string for using it in bucket name
resource "random_string" "random" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket" "bucket" {
  bucket        = "whizbucket-${random_string.random.result}"
  force_destroy = true //allow remove bucket even if some files exist there
}

resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.bucket.id
  key    = "sample.txt"
  source = "files/sample.txt"
  etag   = md5("files/sample.txt") //calculate MD5 hash for content integrity
}

resource "aws_s3_bucket_lifecycle_configuration" "rule" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    id     = "transition-to-one-zone-ia"
    prefix = ""
    transition { //time when file will be able to move in another storage class
      days          = 30
      storage_class = "ONEZONE_IA"
    }
    expiration { //time when file will be able to remove
      days = 120
    }
    status = "Enabled"
  }
  rule {
    id     = "transition-to-glacier"
    prefix = ""
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    expiration {
      days = 120
    }
    status = "Enabled"
  }
}
