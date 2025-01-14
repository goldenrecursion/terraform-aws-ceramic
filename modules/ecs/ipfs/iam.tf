module "ecs_ipfs_task_group" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.3.3"

  name = "ecsIpfsTask-${local.namespace}"

  custom_group_policy_arns = [aws_iam_policy.main.arn]
  group_users              = [module.ecs_ipfs_task_user.iam_user_name]
}

module "ecs_ipfs_task_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.3.3"

  name = "ecsIpfsTask-${local.namespace}"

  create_iam_access_key         = true
  create_iam_user_login_profile = false
  force_destroy                 = false

  tags = local.default_tags
}

resource "aws_iam_policy" "main" {
  name        = "IPFSS3-${local.namespace}"
  path        = "/"
  description = "Allows get, list, and put access for IPFS S3 block storage"

  policy = templatefile("${path.module}/templates/s3_policy.json.tpl", {
    resource  = var.s3_bucket_arn
    directory = var.directory_namespace != "" ? var.directory_namespace : "ipfs"
  })
}

resource "aws_iam_policy" "ecs_exec_policy" {
  name = "ECSExecPermissions-${local.namespace}"

  policy = file("${path.module}/templates/ecs_exec_policy.json")
}


module "ecs_ipfs_task_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.3.3"

  trusted_role_services = [
    "ecs-tasks.amazonaws.com"
  ]

  create_role = true

  role_name         = "ecsIPFSTaskRole-${local.namespace}"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess",
    aws_iam_policy.main.arn,
    aws_iam_policy.ecs_exec_policy.arn
  ]

  tags = local.default_tags
}

module "ecs_task_execution_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.3.3"

  trusted_role_services = [
    "ecs-tasks.amazonaws.com"
  ]

  create_role = true

  role_name         = "ecsTaskExecutionRole-${local.namespace}"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]

  tags = local.default_tags
}

module "s3_data_sync_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.3.3"

  trusted_role_services = [
    "datasync.amazonaws.com"
  ]

  create_role = var.enable_repo_backup_to_s3

  role_name         = "S3DataSyncRole-${local.namespace}"
  role_requires_mfa = false

  custom_role_policy_arns = var.enable_repo_backup_to_s3 ? [
    aws_iam_policy.s3_ipfs_repo_data_sync[0].arn
  ] : []

  tags = local.default_tags
}

resource "aws_iam_policy" "s3_ipfs_repo_data_sync" {
  count = var.enable_repo_backup_to_s3 ? 1 : 0
  name  = "S3DataSyncPolicy-${local.namespace}"

  policy = templatefile("${path.module}/templates/s3_data_sync_policy.json.tpl", {
    resource = var.s3_repo_backup_bucket_arn
  })
}
