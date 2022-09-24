output "eks_role" {
    value = aws_iam_role.ekscustrole.arn
}

output "ec2node_role" {
    value = aws_iam_role.ec2nodecustrole.arn
}

output "fargatenode_role" {
    value = aws_iam_role.fargatenodecustrole.arn
}