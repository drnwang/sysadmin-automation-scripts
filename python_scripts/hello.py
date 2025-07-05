#!/usr/bin/env python3
import platform
import os

print("System Info:")
print(f"OS: {platform.system()} {platform.release()}")
print(f"Architecture: {platform.machine()}")
print(f"CPU Count: {os.cpu_count()}")
