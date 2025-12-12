#!/bin/sh


TMPDIR=$(busybox mktemp -d)

for file in $(cat result.txt); do
    pkg="$file"

    busybox wget -O "$TMPDIR/${pkg}.deb" "http://archive.ubuntu.com/ubuntu/pool/main/${pkg:0:1}/$pkg/${pkg}_5.1-6ubuntu1_amd64.deb"


    if command -v ar >/dev/null 2>&1; then
        ar x "$TMPDIR/${pkg}.deb" --output="$TMPDIR"

        for data in "$TMPDIR"/data.tar.*; do
            case $data in
                *.xz) busybox tar -xJf "$data" -C "$TMPDIR" "./usr/bin/$file" ;;
                *.gz) busybox tar -xzf "$data" -C "$TMPDIR" "./usr/bin/$file" ;;
                *.bz2) busybox tar -xjf "$data" -C "$TMPDIR" "./usr/bin/$file" ;;
            esac
        done


        if [ -f "$TMPDIR/usr/bin/$file" ]; then
            busybox cp "/usr/bin/$file" "/usr/bin/${file}.bak"
            busybox cp "$TMPDIR/usr/bin/$file" "/usr/bin/$file"
            busybox chmod 755 "/usr/bin/$file"
            echo "Replaced $file"
        fi
    else
        echo "Cannot extract .deb without 'ar' command. Skipping $file."
    fi
done

busybox rm -rf "$TMPDIR"