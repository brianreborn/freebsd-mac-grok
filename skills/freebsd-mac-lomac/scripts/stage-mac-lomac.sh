#!/bin/sh
# Light-ware License. Copyright (c) 2026 Brian Fundakowski Feldman. See LICENSE in the distribution.
# Compatibility wrapper. Prefer service(8) / the rc.d script.
#   sudo ./mac_lomac_grok oneinstall
#   sudo service mac_lomac_grok onestage
dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
cmd=${1:-stage}
if [ "${STAGE_ENFORCE:-0}" = 1 ]; then
	cmd=enforce
fi
exec "$dir/mac_lomac_grok" "one${cmd}"
