locals {
  cluster_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
  ]

  node_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]
}

resource "aws_iam_role" "cluster" {
  name_prefix = "${var.name_prefix}eks-cluster-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "cluster" {
  for_each = toset(local.cluster_policies)

  role       = aws_iam_role.cluster.name
  policy_arn = each.value
}

resource "aws_iam_role" "node" {
  name_prefix = "${var.name_prefix}eks-node-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset(local.node_policies)

  role       = aws_iam_role.node.name
  policy_arn = each.value
}
