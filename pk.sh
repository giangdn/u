#!/bin/sh
while read f; do
    [ -z "$f" ] && continue
    pkg=$(busybox grep -l "^/usr/bin/$f$" /var/lib/dpkg/info/*.list 2>/dev/null | busybox head -1 | busybox sed "s|.*/||;s/\.list$//")
    if [ -n "$pkg" ]; then
        echo "$f: $pkg"
    else
        echo "$f: NOT_FOUND"
    fi
done < result.txt > pk.txt