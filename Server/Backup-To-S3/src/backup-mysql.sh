#!/bin/bash
##### VARIABLES
# Backup Directory - WITH TAILING SLASH!
OUTPUT="/01_data/backup/"
# MySQL credentials
USER='root'
PASSWORD='MySQL_ROOT_PASSWORD'
HOST='127.0.0.1'
PORT=3306

##### EXECUTE THE BACKUP
TIMESTAMP=`date +%Y%m%d_%H`;
echo "Starting MySQL Backup $TIMESTAMP";
echo `date`;
rm -rf $OUTPUT*.sql.zst
mkdir -p $OUTPUT
databases=`mysql --user=$USER --password=$PASSWORD --host=$HOST --port=$PORT -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`
for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != _* ]] && [[ "$db" != "mysql" ]] && [[ "$db" != "performance_schema" ]] ; then
        echo "Dumping database: $db"
        mysqldump --single-transaction --routines --triggers --user=$USER --password=$PASSWORD --host=$HOST --port=$PORT --databases $db > $OUTPUT/backup-mysql-$TIMESTAMP-$db.sql
        zstd --ultra -22 --rm -q $OUTPUT/backup-mysql-$TIMESTAMP-$db.sql
    fi
done
echo "Finished MySQL Backup";
echo `date`;