variable "environment" {
  type        = string
  description = "Miljø: test eller prod."

  validation {
    condition     = contains(["test", "prod"], var.environment)
    error_message = "environment må være test eller prod."
  }
}

variable "location" {
  type        = string
  description = "Azure-region."
}
