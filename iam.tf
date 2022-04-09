data "aws_iam_policy" "AmazonEKSClusterPolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy" "AmazonEKSVPCResourceController" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

data "aws_iam_policy_document" "eks_cluster_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name               = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_trust_policy.json
  managed_policy_arns = [
    data.aws_iam_policy.AmazonEKSClusterPolicy.arn,
    data.aws_iam_policy.AmazonEKSVPCResourceController.arn
  ]
  depends_on = [
    data.aws_iam_policy.AmazonEKSClusterPolicy,
    data.aws_iam_policy.AmazonEKSVPCResourceController,
    data.aws_iam_policy_document.eks_cluster_trust_policy
  ]
}

data "aws_iam_policy" "AmazonEKSWorkerNodePolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

data "aws_iam_policy" "AmazonEKS_CNI_Policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

data "aws_iam_policy" "AmazonEC2ContainerRegistryReadOnly" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "eks_node_group_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_node_group_role" {
  name               = "eks-node-group-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_group_trust_policy.json
  managed_policy_arns = [
    data.aws_iam_policy.AmazonEKSWorkerNodePolicy.arn,
    data.aws_iam_policy.AmazonEKS_CNI_Policy.arn,
    data.aws_iam_policy.AmazonEC2ContainerRegistryReadOnly.arn,
    data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
  ]
  depends_on = [
    data.aws_iam_policy.AmazonEKSWorkerNodePolicy,
    data.aws_iam_policy.AmazonEKS_CNI_Policy,
    data.aws_iam_policy.AmazonEC2ContainerRegistryReadOnly,
    data.aws_iam_policy_document.eks_node_group_trust_policy,
    data.aws_iam_policy.AmazonSSMManagedInstanceCore
  ]
}

resource "aws_iam_policy" "eks_lambda_policy" {
  name        = "eks-lambda-policy"
  path        = "/"
  description = "EKS Lambda Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
        ]
        Resource = "arn:aws:logs:us-east-1:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:us-east-1:*:log-group:/aws/lambda/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:us-east-1:*:subnet/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_iam_policy_document" "lambda_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_lambda_role" {
  name               = "eks-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
  depends_on = [
    data.aws_iam_policy_document.lambda_trust_policy
  ]
}

resource "aws_iam_policy_attachment" "eks_lambda_policy_attachment" {
  name       = "eks-lambda-policy-attachment"
  roles      = [aws_iam_role.eks_lambda_role.name]
  policy_arn = aws_iam_policy.eks_lambda_policy.arn
  depends_on = [
    aws_iam_policy.eks_lambda_policy,
    aws_iam_role.eks_lambda_role
  ]
}
