output "worker_ip" {
  description = "Worker VM IP address"
  value       = var.worker_ip
}

output "db_ip" {
  description = "DB VM IP address"
  value       = var.db_ip
}

output "ssh_worker" {
  description = "SSH command to connect to worker"
  value       = "ssh -i ~/.ssh/deployment_lab4 ansible@${var.worker_ip}"
}

output "ssh_db" {
  description = "SSH command to connect to db"
  value       = "ssh -i ~/.ssh/deployment_lab4 ansible@${var.db_ip}"
}