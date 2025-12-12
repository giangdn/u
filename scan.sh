#!/bin/sh
for f in /usr/bin/*; do
  busybox grep -l Titan "$f" 2>/dev/null && busybox basename "$f"
done > result.txt