resource "aws_eks_cluster" "knote-cluster" {
  name     = "${var.prefix}-cluster"
  role_arn = aws_iam_role.eks-cluster.arn
  version  = "1.24"

  vpc_config {
    security_group_ids = [aws_security_group.cluster-sg.id]
    subnet_ids = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id,
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]

  tags = local.common_tags

}

resource "aws_eks_node_group" "public-node-group" {
  cluster_name    = aws_eks_cluster.knote-cluster.name
  node_group_name = "public-node-group"
  node_role_arn   = aws_iam_role.node-group-role.arn
  subnet_ids      = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  ami_type       = "AL2_x86_64"
  disk_size      = 8
  instance_types = ["t2.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_eks_node_group" "private-node-group" {
  cluster_name    = aws_eks_cluster.knote-cluster.name
  node_group_name = "private-node-group"
  node_role_arn   = aws_iam_role.node-group-role.arn
  subnet_ids      = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  ami_type       = "AL2_x86_64"
  disk_size      = 8
  instance_types = ["t2.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]
}