output "s3_bucket_name" {
  description = "The name of the S3 bucket storing the scripts."
  value       = aws_s3_bucket.scripts_bucket.id
}

output "script_urls" {
  description = "A map of script filenames to their S3 URLs."
  value       = { for k, v in aws_s3_object.scripts : k => "s3://${aws_s3_bucket.scripts_bucket.id}/${v.key}" }
}
