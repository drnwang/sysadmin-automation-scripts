#!/bin/bash
# Check disk usage and alert if usage exceeds 80%
THRESHOLD=80

df -h | awk 'NR==1 || $5+0 > '"$THRESHOLD"' { print }'
