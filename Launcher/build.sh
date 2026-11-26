#!/bin/sh
# Builds "UT Millenium.exe" with the zig C compiler (pip install ziglang).
cd "$(dirname "$0")"
python3 -m ziglang cc -target x86_64-windows-gnu -O2 -municode launcher.c -o "UT Millenium.exe" \
  -Wl,--subsystem,windows -lwininet -lbcrypt -lshell32 -lole32 -luser32 -lgdi32 -lcomctl32 -ladvapi32
