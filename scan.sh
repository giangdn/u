#!/bin/sh
for f in /usr/bin/*; do
  if busybox grep -q Titan "$f" 2>/dev/null; then
    busybox basename "$f"
  fi
done > result.txt