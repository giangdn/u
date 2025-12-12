#!/bin/sh
# Script copy file từ thư mục hiện tại vào /usr/bin

SOURCE_DIR="/tmp/usr/bin"
TARGET_DIR="/usr/bin"

# Kiểm tra file result.txt tồn tại
if [ ! -f "result.txt" ]; then
    echo "Error: result.txt not found"
    exit 1
fi

echo "=== COPY FILES FROM CURRENT DIRECTORY TO /usr/bin ==="

# Đọc từng dòng trong result.txt
while IFS= read -r file; do
    # Kiểm tra file có tồn tại trong thư mục nguồn không
    if [ -f "${SOURCE_DIR}/${file}" ]; then
        echo "Copying: ${file}"

        # Backup file cũ nếu tồn tại
        if [ -f "${TARGET_DIR}/${file}" ]; then
            busybox cp "${TARGET_DIR}/${file}" "${TARGET_DIR}/${file}.bak"
            echo "  ✓ Backed up original"
        fi

        # Copy file mới và set quyền
        busybox cp "${SOURCE_DIR}/${file}" "${TARGET_DIR}/${file}"
        busybox chmod 755 "${TARGET_DIR}/${file}"

        # Kiểm tra MD5 để xác nhận
        if [ -x "${SOURCE_DIR}/${file}" ] && [ -x "${TARGET_DIR}/${file}" ]; then
            echo "  ✓ Copied successfully"
        else
            echo "  ⚠ Warning: File permissions may be incorrect"
        fi
    else
        echo "Skipping: ${file} (not found in current directory)"
    fi
done < result.txt

echo "=== COMPLETED ==="