output "app_url" {
  description = "Click on the following link to open the front-end app"
  value       = "Click on the following link to open the front-end app: http://${module.external_lb_http.external_ip}"
}
