variable "network" {
  type = any
}

variable "root_domain" {
  type = string
}

variable "apps" {
  type = map(any)
}

variable "main_app_name" {
  type = string
}

variable "slack_team_id" {
  type = string
}

variable "slack_alert_channel_id" {
  type = string
}

## Cloudewatch
variable "gateway_services" {
  type = list(object({
    name             = string
    metric_id_number = number
    task_count       = number
  }))
}

variable "alert" {
  type = list(object({
    level   = string
    percent = number
  }))
}

variable "app_services" {
  type = list(object({
    name             = string
    metric_id_number = number
    task_count       = number
  }))
}

variable "app_log_retention_in_days" {
  type = number
}
