#!/bin/bash

VBM="/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
VM_NAME="$1"

echo "==> Destroying VM: $VM_NAME"

"$VBM" controlvm "$VM_NAME" poweroff 2>/dev/null || true
sleep 3
"$VBM" unregistervm "$VM_NAME" --delete 2>/dev/null || true

echo "==> VM $VM_NAME destroyed"