variable "name" {
    description = "Name of the spotinst account to create."
    type = string
    default = null
}
variable "token" {
    type = string
}
variable "profile" {
    type = string
    default = null
}