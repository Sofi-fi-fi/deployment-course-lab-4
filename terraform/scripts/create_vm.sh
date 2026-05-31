#!/bin/bash
set -e

VBM="/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
VM_NAME="$1"
DISK_PATH="$2"
BASE_DISK="$3"
CI_ISO="$4"
MEMORY="$5"
CPUS="$6"
HOST_PORT="$7"

WIN_DISK_PATH=$(wslpath -w "$DISK_PATH")
WIN_BASE_DISK=$(wslpath -w "$BASE_DISK")
WIN_CI_ISO=$(wslpath -w "$CI_ISO")

echo "==> Creating VM: $VM_NAME"

if "$VBM" list vms | grep -q "\"$VM_NAME\""; then
  echo "==> VM $VM_NAME already exists, removing..."
  "$VBM" controlvm "$VM_NAME" poweroff 2>/dev/null || true
  sleep 3
  "$VBM" unregistervm "$VM_NAME" --delete 2>/dev/null || true
  sleep 2
fi

rm -f "$DISK_PATH"

echo "==> Cloning base disk..."
"$VBM" clonemedium disk "$WIN_BASE_DISK" "$WIN_DISK_PATH" --format VMDK

echo "==> Creating VM..."
"$VBM" createvm --name "$VM_NAME" --ostype Ubuntu_64 --register

"$VBM" modifyvm "$VM_NAME" \
  --memory "$MEMORY" \
  --cpus "$CPUS" \
  --boot1 disk \
  --audio none \
  --usb off

"$VBM" modifyvm "$VM_NAME" --nic1 nat
"$VBM" modifyvm "$VM_NAME" \
  --nic2 hostonly \
  --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter"

"$VBM" modifyvm "$VM_NAME" --natpf1 "ssh,tcp,,$HOST_PORT,,22"

"$VBM" storagectl "$VM_NAME" \
  --name "SATA" \
  --add sata \
  --controller IntelAhci \
  --portcount 3

"$VBM" storageattach "$VM_NAME" \
  --storagectl "SATA" \
  --port 0 --device 0 \
  --type hdd \
  --medium "$WIN_DISK_PATH"

"$VBM" storageattach "$VM_NAME" \
  --storagectl "SATA" \
  --port 1 --device 0 \
  --type dvddrive \
  --medium "$WIN_CI_ISO"

echo "==> Starting VM $VM_NAME..."
"$VBM" startvm "$VM_NAME" --type headless

echo "==> VM $VM_NAME started successfully"