#!/bin/bash
set -e

if [[ "$(basename $(pwd))" != "jhalfs" ]];
then
    echo "Error: this script must be run from the 'jhalfs' directory"
    exit 1
fi

# https://github.com/moby/moby/issues/27886#issuecomment-417074845
LOOPDEV=$(cat build_dir.dev)

# drop the first line, as this is our LOOPDEV itself, but we only want the child partitions
PARTITIONS=$(lsblk --raw --output "MAJ:MIN" --noheadings ${LOOPDEV} | tail -n +2)
COUNTER=1
for i in $PARTITIONS; do
    MAJ=$(echo $i | cut -d: -f1)
    MIN=$(echo $i | cut -d: -f2)
    if [ ! -e "${LOOPDEV}p${COUNTER}" ]; then echo "mknod ${LOOPDEV}p${COUNTER} b $MAJ $MIN" && mknod ${LOOPDEV}p${COUNTER} b $MAJ $MIN; fi
    COUNTER=$((COUNTER + 1))
done
