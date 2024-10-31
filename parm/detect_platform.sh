#!/bin/sh
#
# Detect HPC platforms
#
if [[ -d /scratch2/NAGAPE ]] ; then
  PLATFORM="hera"
elif [[ -d /work/noaa ]]; then
  hoststr=$(hostname)
  if [[ "$hoststr" == "hercules"* ]]; then
    PLATFORM="hercules"
  else
    PLATFORM="orion"
  fi
elif [[ -d /ncrc ]]; then
  PLATFORM="gaea"
elif [[ -d /glade ]]; then
  PLATFORM="derecho"
elif [[ -d /lfs4/HFIP ]] ; then
  PLATFORM="jet"
elif [[ -d /lfs/h2 ]] ; then
  PLATFORM="wcoss2"
else
  PLATFORM="unknown"
fi
MACHINE="${PLATFORM}"

