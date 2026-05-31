variable "vboxmanage_path" {
  description = "Path to VBoxManage executable"
  type        = string
  default     = "/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
}

variable "worker_ip" {
  description = "IP address for worker VM"
  type        = string
  default     = "192.168.56.10"
}

variable "db_ip" {
  description = "IP address for db VM"
  type        = string
  default     = "192.168.56.11"
}

variable "vm_memory" {
  description = "RAM in MB for each VM"
  type        = number
  default     = 2048
}

variable "vm_cpus" {
  description = "CPU count for each VM"
  type        = number
  default     = 2
}

variable "ssh_public_key" {
  description = "SSH public key for ansible user"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBbHuS2hb9/UV7sa+UeUp5eVJrv+SwEO5d1M2zvAsqiA sofi@Aorus"
}