resource "aws_key_pair" "this" {
  key_name   = "kiskey"
  public_key = var.public_key
}
