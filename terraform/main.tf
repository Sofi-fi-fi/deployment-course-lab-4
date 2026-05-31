terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

locals {
  module_dir  = abspath(path.module)
  base_disk   = "${local.module_dir}/ubuntu-22.04-cloud.vmdk"
  worker_disk = "${local.module_dir}/worker.vmdk"
  db_disk     = "${local.module_dir}/db.vmdk"
  worker_iso  = "${local.module_dir}/ci-worker.iso"
  db_iso      = "${local.module_dir}/ci-db.iso"
  worker_ci   = "${local.module_dir}/cloud-init/worker"
  db_ci       = "${local.module_dir}/cloud-init/db"
}

resource "null_resource" "worker_iso" {
  triggers = {
    userdata = filemd5("${local.module_dir}/cloud-init/worker.yaml")
  }

  provisioner "local-exec" {
    command = <<-BASH
      mkdir -p "${local.worker_ci}"
      cp "${local.module_dir}/cloud-init/worker.yaml" "${local.worker_ci}/user-data"
      bash "${local.module_dir}/scripts/make_iso.sh" \
        "${local.worker_ci}" \
        "${local.worker_iso}" \
        "worker"
    BASH
  }
}

resource "null_resource" "db_iso" {
  triggers = {
    userdata = filemd5("${local.module_dir}/cloud-init/db.yaml")
  }

  provisioner "local-exec" {
    command = <<-BASH
      mkdir -p "${local.db_ci}"
      cp "${local.module_dir}/cloud-init/db.yaml" "${local.db_ci}/user-data"
      bash "${local.module_dir}/scripts/make_iso.sh" \
        "${local.db_ci}" \
        "${local.db_iso}" \
        "db"
    BASH
  }
}

resource "null_resource" "worker_vm" {
  depends_on = [null_resource.worker_iso, null_resource.db_vm]

  triggers = {
    vm_name = "lab4-worker"
  }

  provisioner "local-exec" {
    command = <<-BASH
      bash "${local.module_dir}/scripts/create_vm.sh" \
        "lab4-worker" \
        "${local.worker_disk}" \
        "${local.base_disk}" \
        "${local.worker_iso}" \
        "${var.vm_memory}" \
        "${var.vm_cpus}" \
        "2222"
    BASH
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-BASH
      bash "/mnt/d/University/deployment-course-lab-4/terraform/scripts/destroy_vm.sh" "lab4-worker"
    BASH
  }
}

resource "null_resource" "db_vm" {
  depends_on = [null_resource.db_iso]

  triggers = {
    vm_name = "lab4-db"
  }

  provisioner "local-exec" {
    command = <<-BASH
      bash "${local.module_dir}/scripts/create_vm.sh" \
        "lab4-db" \
        "${local.db_disk}" \
        "${local.base_disk}" \
        "${local.db_iso}" \
        "${var.vm_memory}" \
        "${var.vm_cpus}" \
        "2223"
    BASH
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-BASH
      bash "/mnt/d/University/deployment-course-lab-4/terraform/scripts/destroy_vm.sh" "lab4-db"
    BASH
  }
}

resource "null_resource" "wait_for_vms" {
  depends_on = [null_resource.worker_vm, null_resource.db_vm]

  provisioner "local-exec" {
    command = <<-BASH
      echo "==> Waiting 60 seconds for VMs to boot and cloud-init to finish..."
      sleep 60
      echo "==> Checking SSH on worker (localhost:2222)..."
      timeout 120 bash -c 'until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ~/.ssh/deployment_lab4 -p 2222 ansible@127.0.0.1 "echo worker ok" 2>/dev/null; do sleep 5; done'
      echo "==> Checking SSH on db (localhost:2223)..."
      timeout 120 bash -c 'until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ~/.ssh/deployment_lab4 -p 2223 ansible@127.0.0.1 "echo db ok" 2>/dev/null; do sleep 5; done'
      echo "==> Both VMs are ready!"
    BASH
  }
}