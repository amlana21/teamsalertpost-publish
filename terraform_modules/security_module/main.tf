

# *********************************************eks custom role*****************************************

data "aws_iam_policy" "eksclusterpolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "eks-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ekscustrole" {
    name               = "ekscustrole"
    assume_role_policy = data.aws_iam_policy_document.eks-assume-role-policy.json
}

resource "aws_iam_role_policy_attachment" "ekscustroleattach" {
  role       = "${aws_iam_role.ekscustrole.name}"
  policy_arn = "${data.aws_iam_policy.eksclusterpolicy.arn}"
}

# *********************************************end eks custom role*****************************************



# *********************************************eks_managed node group custom role*****************************************
data "aws_iam_policy_document" "ec2node-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ec2nodepolicy1" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

data "aws_iam_policy" "ec2nodepolicy2" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_policy" "ec2nodepolicy3" {
  arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role" "ec2nodecustrole" {
    name               = "ec2nodecustrole"
    assume_role_policy = data.aws_iam_policy_document.ec2node-assume-role-policy.json
}

resource "aws_iam_role_policy_attachment" "ec2noderoleattach" {
  role       = "${aws_iam_role.ec2nodecustrole.name}"
  policy_arn = "${data.aws_iam_policy.ec2nodepolicy1.arn}"
}

resource "aws_iam_role_policy_attachment" "ec2noderoleattach1" {
  role       = "${aws_iam_role.ec2nodecustrole.name}"
  policy_arn = "${data.aws_iam_policy.ec2nodepolicy2.arn}"
}

resource "aws_iam_role_policy_attachment" "ec2noderoleattach2" {
  role       = "${aws_iam_role.ec2nodecustrole.name}"
  policy_arn = "${data.aws_iam_policy.ec2nodepolicy3.arn}"
}


# *********************************************end eks_managed node group custom role*****************************************




# *********************************************fargate node group custom role*****************************************
data "aws_iam_policy_document" "fargatenode-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "fargatepolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}


resource "aws_iam_role" "fargatenodecustrole" {
    name               = "fargatenodecustrole"
    assume_role_policy = data.aws_iam_policy_document.fargatenode-assume-role-policy.json
}

resource "aws_iam_role_policy_attachment" "fargateroleattach" {
  role       = "${aws_iam_role.fargatenodecustrole.name}"
  policy_arn = "${data.aws_iam_policy.fargatepolicy.arn}"
}


# *********************************************end fargate node group custom role*****************************************



# *********************cert for https loadbalancer**************
resource "aws_acm_certificate" "teams_api_cert" {
  domain_name       = "<domain>"
  validation_method = "DNS"

  tags = {
    APP = "teams_api"
  }
}
# *********************end cert for https loadbalancer**************