#!/bin/bash
find /data/base/wal_archive/ -type f -mtime +1 -exec rm {} \;
