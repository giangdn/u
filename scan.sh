#!/bin/bash
# Script tìm file bị nhiễm Titan trong /usr/bin
# Tác giả: Hệ thống khắc phục sự cố
# Phiên bản: 1.0

set -e  # Dừng khi có lỗi

LOG_FILE="/tmp/titan_scan_results_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="/root/infected_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "================================================" | tee "$LOG_FILE"
echo "SCAN TITAN MALWARE TRONG /usr/bin" | tee -a "$LOG_FILE"
echo "Thời gian: $(date)" | tee -a "$LOG_FILE"
echo "================================================" | tee -a "$LOG_FILE"

# Hàm kiểm tra file có chứa Titan không
check_file_for_titan() {
    local file="$1"

    # Kiểm tra file tồn tại và có thể đọc
    if [ ! -f "$file" ] || [ ! -r "$file" ]; then
        return 1
    fi

    # Sử dụng strings để tìm Titan trong file binary
    if command -v strings >/dev/null 2>&1; then
        if strings "$file" 2>/dev/null | grep -q "Titan"; then
            return 0  # Tìm thấy
        fi
    elif command -v busybox >/dev/null 2>&1; then
        if busybox strings "$file" 2>/dev/null | busybox grep -q "Titan"; then
            return 0  # Tìm thấy
        fi
    else
        # Nếu không có strings, dùng grep -a
        if grep -a "Titan" "$file" 2>/dev/null | grep -q "Titan"; then
            return 0  # Tìm thấy
        fi
    fi

    return 1  # Không tìm thấy
}

# Hàm backup file bị nhiễm
backup_infected_file() {
    local file="$1"
    local backup_path="$BACKUP_DIR/$(basename "$file").infected"

    echo "  [BACKUP] $file -> $backup_path" | tee -a "$LOG_FILE"
    cp "$file" "$backup_path"
}

# Hàm phân tích file
analyze_file() {
    local file="$1"

    echo "================================================" | tee -a "$LOG_FILE"
    echo "FILE: $file" | tee -a "$LOG_FILE"
    echo "================================================" | tee -a "$LOG_FILE"

    # Thông tin cơ bản
    echo "  [INFO] Kích thước: $(ls -lh "$file" | awk '{print $5}')" | tee -a "$LOG_FILE"
    echo "  [INFO] Loại file: $(file "$file" 2>/dev/null || echo "Không xác định")" | tee -a "$LOG_FILE"

    # MD5 hash
    if command -v md5sum >/dev/null 2>&1; then
        echo "  [HASH] MD5: $(md5sum "$file" | awk '{print $1}')" | tee -a "$LOG_FILE"
    fi

    # Ngày sửa đổi
    echo "  [TIME] Sửa đổi: $(stat -c %y "$file" 2>/dev/null || ls -la "$file" | awk '{print $6,$7,$8}')" | tee -a "$LOG_FILE"

    # Kiểm tra ELF binary
    if file "$file" 2>/dev/null | grep -q "ELF"; then
        echo "  [TYPE] ELF Executable" | tee -a "$LOG_FILE"

        # Kiểm tra strings chứa Titan
        echo "  [SCAN] Tìm chuỗi 'Titan'..." | tee -a "$LOG_FILE"
        if command -v strings >/dev/null 2>&1; then
            strings "$file" 2>/dev/null | grep -i "Titan" | head -10 | while read line; do
                echo "    -> $line" | tee -a "$LOG_FILE"
            done
        fi
    fi

    # Kiểm tra xem có phải shell script không
    if head -n 5 "$file" 2>/dev/null | grep -q "^#!/bin/bash\|^#!/bin/sh"; then
        echo "  [TYPE] Shell Script" | tee -a "$LOG_FILE"
        echo "  [SCAN] Tìm 'Titan' trong script..." | tee -a "$LOG_FILE"
        grep -n -i "Titan" "$file" 2>/dev/null | head -5 | while read line; do
            echo "    -> $line" | tee -a "$LOG_FILE"
        done
    fi
}

# Hàm quét toàn bộ /usr/bin
scan_usr_bin() {
    echo "[1/3] Quét /usr/bin..." | tee -a "$LOG_FILE"
    echo "Tìm tất cả file trong /usr/bin..." | tee -a "$LOG_FILE"

    local total_files=0
    local infected_files=0

    # Tìm tất cả file thông thường trong /usr/bin
    find /usr/bin -type f 2>/dev/null | while read file; do
        total_files=$((total_files + 1))

        # Hiển thị tiến độ mỗi 100 file
        if [ $((total_files % 100)) -eq 0 ]; then
            echo "  Đã quét $total_files file..." | tee -a "$LOG_FILE"
        fi

        if check_file_for_titan "$file"; then
            infected_files=$((infected_files + 1))
            echo "" | tee -a "$LOG_FILE"
            echo "⚠️  PHÁT HIỆN TITAN: $file" | tee -a "$LOG_FILE"

            # Backup file bị nhiễm
            backup_infected_file "$file"

            # Phân tích chi tiết
            analyze_file "$file"
        fi
    done

    echo "" | tee -a "$LOG_FILE"
    echo "[KẾT QUẢ] Tổng số file đã quét: $total_files" | tee -a "$LOG_FILE"
    echo "[KẾT QUẢ] Số file bị nhiễm Titan: $infected_files" | tee -a "$LOG_FILE"
}

# Hàm kiểm tra các file hệ thống quan trọng
check_critical_binaries() {
    echo "" | tee -a "$LOG_FILE"
    echo "[2/3] Kiểm tra file hệ thống quan trọng..." | tee -a "$LOG_FILE"

    local critical_binaries=(
        "/usr/bin/ls"
        "/usr/bin/apt"
        "/usr/bin/apt-get"
        "/usr/bin/dpkg"
        "/usr/bin/sudo"
        "/usr/bin/bash"
        "/usr/bin/sh"
        "/usr/bin/tar"
        "/usr/bin/gzip"
        "/usr/bin/xz"
        "/usr/bin/find"
        "/usr/bin/grep"
        "/usr/bin/sed"
        "/usr/bin/awk"
        "/usr/bin/ps"
        "/usr/bin/netstat"
        "/usr/bin/ss"
        "/usr/bin/ip"
        "/usr/bin/systemctl"
        "/usr/bin/journalctl"
        "/usr/bin/crontab"
        "/usr/bin/wget"
        "/usr/bin/curl"
        "/usr/bin/ssh"
        "/usr/bin/scp"
        "/usr/bin/python3"
        "/usr/bin/perl"
    )

    for binary in "${critical_binaries[@]}"; do
        if [ -f "$binary" ]; then
            if check_file_for_titan "$binary"; then
                echo "  ⚠️  $binary: BỊ NHIỄM" | tee -a "$LOG_FILE"
                backup_infected_file "$binary"
            else
                echo "  ✅ $binary: Sạch" | tee -a "$LOG_FILE"
            fi
        fi
    done
}

# Hàm kiểm tra file ELF bị sửa đổi gần đây
check_recent_elf_files() {
    echo "" | tee -a "$LOG_FILE"
    echo "[3/3] Kiểm tra file ELF mới/chỉnh sửa gần đây..." | tee -a "$LOG_FILE"

    # Tìm file ELF được sửa đổi trong 7 ngày qua
    find /usr/bin -type f -mtime -7 2>/dev/null | while read file; do
        if file "$file" 2>/dev/null | grep -q "ELF"; then
            echo "  📄 $file" | tee -a "$LOG_FILE"
            echo "    Sửa đổi: $(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1)" | tee -a "$LOG_FILE"

            if check_file_for_titan "$file"; then
                echo "    ⚠️  CHỨA TITAN!" | tee -a "$LOG_FILE"
                backup_infected_file "$file"
            fi
        fi
    done
}

# Hàm tạo báo cáo
generate_report() {
    echo "" | tee -a "$LOG_FILE"
    echo "================================================" | tee -a "$LOG_FILE"
    echo "BÁO CÁO TỔNG HỢP" | tee -a "$LOG_FILE"
    echo "================================================" | tee -a "$LOG_FILE"
    echo "1. File log: $LOG_FILE" | tee -a "$LOG_FILE"
    echo "2. Backup file nhiễm: $BACKUP_DIR" | tee -a "$LOG_FILE"
    echo "3. Thời gian hoàn tất: $(date)" | tee -a "$LOG_FILE"

    # Đếm số file backup
    local backup_count=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
    echo "4. Số file bị nhiễm đã backup: $backup_count" | tee -a "$LOG_FILE"

    if [ "$backup_count" -gt 0 ]; then
        echo "" | tee -a "$LOG_FILE"
        echo "DANH SÁCH FILE BỊ NHIỄM:" | tee -a "$LOG_FILE"
        ls -la "$BACKUP_DIR/" | tee -a "$LOG_FILE"

        echo "" | tee -a "$LOG_FILE"
        echo "📌 HƯỚNG DẪN KHẮC PHỤC:" | tee -a "$LOG_FILE"
        echo "1. Xóa file nhiễm: rm -f /usr/bin/[tên_file]" | tee -a "$LOG_FILE"
        echo "2. Tải file sạch: wget -O /usr/bin/[tên_file] [URL]" | tee -a "$LOG_FILE"
        echo "3. Cấp quyền: chmod 755 /usr/bin/[tên_file]" | tee -a "$LOG_FILE"
        echo "4. Kiểm tra: strings /usr/bin/[tên_file] | grep -i titan" | tee -a "$LOG_FILE"
    else
        echo "" | tee -a "$LOG_FILE"
        echo "✅ KHÔNG TÌM THẤY FILE NÀO CHỨA TITAN TRONG /usr/bin" | tee -a "$LOG_FILE"
    fi
}

# ================== CHƯƠNG TRÌNH CHÍNH ==================

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Cảnh báo: Nên chạy script với quyền root để đọc tất cả file!"
    echo "   Sử dụng: sudo bash $0"
    echo "   Tiếp tục với quyền hiện tại..."
    echo ""
fi

# Tạo banner
cat << "EOF"
╔══════════════════════════════════════════╗
║     SCAN TITAN MALWARE IN /usr/bin       ║
║         Ubuntu 22.04 Recovery            ║
╚══════════════════════════════════════════╝
EOF

echo ""

# Chạy các hàm quét
scan_usr_bin
check_critical_binaries
check_recent_elf_files
generate_report

echo ""
echo "✨ Quét hoàn tất! Xem chi tiết trong: $LOG_FILE"