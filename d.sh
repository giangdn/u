#!/bin/sh
# Simple replacement script for infected files

# Tạo backup directory
backup_dir="/tmp/backup_$(date +%s)"
busybox mkdir -p "$backup_dir"

for file in $(cat result.txt); do
    echo "Xử lý: $file"

    # 1. Backup file cũ
    if [ -f "/usr/bin/$file" ]; then
        busybox cp "/usr/bin/$file" "$backup_dir/$file"
        echo "  ✓ Đã backup"
    fi

    # 2. Tải file từ Ubuntu repository (cần biết package name)
    # Đây là ví dụ cho các package phổ biến
    case "$file" in
        "bash")
            busybox wget -O "/tmp/$file" "http://archive.ubuntu.com/ubuntu/pool/main/b/bash/bash_5.1-6ubuntu1_amd64" 2>/dev/null
            ;;
        "ls")
            busybox wget -O "/tmp/$file" "http://archive.ubuntu.com/ubuntu/pool/main/c/coreutils/coreutils_8.32-4.1ubuntu1_amd64" 2>/dev/null
            ;;
        *)
            echo "Không có nguồn thay thế cho $file"
            continue
            ;;
    esac

    # 3. Thay thế nếu tải thành công
    if [ -f "/tmp/$file" ]; then
        busybox cp "/tmp/$file" "/usr/bin/$file"
        busybox chmod 755 "/usr/bin/$file"
        echo "  ✓ Đã thay thế"
        busybox rm "/tmp/$file"
    fi
done

echo "Backup được lưu tại: $backup_dir"