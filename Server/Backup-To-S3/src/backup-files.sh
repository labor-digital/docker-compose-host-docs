#!/bin/bash
source /opt/.duplicity
##### VARIABLES
DEST="$AWS_S3_BUCKET"
# Base Directory - WITH TAILING SLASH!
BASEDIR='/01_data/'

##### EXECUTE THE BACKUP
TIMESTAMP=`date +%Y%m%d_%H`;
echo "Starting File Backup $TIMESTAMP";
echo `date`;

duplicity \
    full \
    --exclude "${BASEDIR}persistent/mysql" \
    --include "${BASEDIR}persistent" \
    --include "${BASEDIR}backup" \
    --exclude "**" \
    / ${DEST} 2>&1

export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_S3_BUCKET=
export PASSPHRASE=

echo "Finished File Backup";
echo `date`;