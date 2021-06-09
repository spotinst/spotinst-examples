output "spot_account_id" {
    description = "spot account_id"
    value = data.external.account.result["account_id"]
}