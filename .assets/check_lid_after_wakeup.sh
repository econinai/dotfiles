#!/bin/bash
sleep 2

if grep -q "closed" /proc/acpi/button/lid/*/state; then
    systemctl suspend
fi
