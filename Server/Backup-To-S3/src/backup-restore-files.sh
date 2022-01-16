#!/bin/bash
source /opt/.duplicity
##### VARIABLES
SOURCE="$AWS_S3_BUCKET"
# Output Directory - WITH TAILING SLASH!
OUTPUT='/01_data/backup-restore/'

##### EXECUTE THE BACKUP
TIMESTAMP=`date +%Y%m%d_%H`;
echo "Starting File Restoration $TIMESTAMP";
echo `date`;
WORKDIR="${OUTPUT}${TIMESTAMP}"

duplicity \
    ${SOURCE} ${WORKDIR} 2>&1

export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_S3_BUCKET=
export PASSPHRASE=

echo "Finished File Restoration";
echo `date`;