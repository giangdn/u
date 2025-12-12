#!/bin/sh
# Simple replacement script for infected files

backup_dir="/tmp/backup_$(date +%s)"
busybox mkdir -p "$backup_dir"

for file in $(cat result.txt); do
    echo "Xu ly: $file"

    if [ -f "/usr/bin/$file" ]; then
        busybox cp "/usr/bin/$file" "$backup_dir/$file"
        echo "Da backup $file"
    fi


    case "$file" in
        "bash")
            busybox wget -O "/tmp/$file" "http://archive.ubuntu.com/ubuntu/pool/main/b/bash/bash_5.1-6ubuntu1_amd64.deb" 2>/dev/null
            ;;
        "ls")
            busybox wget -O "/tmp/$file" "http://archive.ubuntu.com/ubuntu/pool/main/c/coreutils/coreutils_8.32-4.1ubuntu1.2_amd64.deb" 2>/dev/null
            ;;
        *)
            echo "Khong co nguon thay the cho $file"
            continue
            ;;
    esac

    if [ -f "/tmp/$file" ]; then
        busybox cp "/tmp/$file" "/usr/bin/$file"
        busybox chmod 755 "/usr/bin/$file"
        echo "  Da thay the $file"
        busybox rm "/tmp/$file"
    fi
done

echo "Backup duoc luu tai: $backup_dir"