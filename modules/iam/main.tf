locals {
  trusted_roles = concat(
    [
      "arn:aws:iam::${var.aws_account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_edap_platform_devs_*",
    ],
    var.aws_account_id == "975050217262" ? ["arn:aws:iam::${var.aws_account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_platform_devs_onboarding_*"] : [],
  )
}

resource "aws_iam_role_policy" "infra" {
  for_each = toset(var.services)
  name   = "${each.value}-infra"
  role   = aws_iam_role.infra[each.key].id
  policy = templatefile("policies/app-infra.json.tpl", { region = var.region, aws_account_id = var.aws_account_id, service = each.value })
}

resource "aws_iam_role" "infra" {
  for_each = toset(var.services)
  name               = "${each.value}-infra"
  assume_role_policy = templatefile("policies/app-infra-trusted.json.tpl", {
    aws_account_id = var.aws_account_id,
    service        = each.value
    trusted_roles  = local.trusted_roles
  })


  tags = {
    AppName : each.value
  }

  lifecycle {
    ignore_changes = [inline_policy]
  }
}
