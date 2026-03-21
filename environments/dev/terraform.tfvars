aws_region = "ap-southeast-1"

# Restrict to your IP for security — replace with $(curl -s ifconfig.me)/32
# cluster_endpoint_public_access_cidrs = ["YOUR_IP/32"]

tags = {
  Environment = "dev"
  Team        = "platform"
}
