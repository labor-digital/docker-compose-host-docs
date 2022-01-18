# Backup data to S3 bucket

1. Create a new IAM user group: "backup-s3"
2. Add the following configuration as inline policy 
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucketMultipartUploads",
                "s3:AbortMultipartUpload",
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::backup-tigger",
                "arn:aws:s3:::backup-tigger/*"
            ]
        }
    ]
}
```
3. Add new IAM user "with programmatic access" that is part of the "backup-s3" group
4. Install duplicity `sudo apt-get install duplicity python3 pip`
5. Install the boto module through pip `sudo pip install boto`
6. Create new directory at `/01_data/backup` with the root user
7. Install `zstandard` compression library ```sudo apt-get install zstd```
8. Copy `src/backup-files.sh` to `/opt/backup-files.sh`
9. Add a new file at `/opt/.duplicity`, paste and adjust the following lines:
```
# GPG encryption passphrase
export PASSPHRASE="PASSPHRASE"
# the IAM user credentials
export AWS_ACCESS_KEY_ID="AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="AWS_SECRET_ACCESS_KEY"
export AWS_S3_BUCKET="s3://s3-eu-central-1.amazonaws.com/<bucket-name>"
```
10. set the correct access rights: `chmod 0600 /opt/.duplicity`
11. Adjust the variables inside the script to match the setup
12. Allow execution `chmod +x /opt/backup-files.sh`
13. Add the cronjob `crontab -e`
14. Add and save: `0 2 * * * /opt/backup-files.sh`

## Mysql/Mariadb backup (optional)
1. Copy `src/backup-mysql.sh` to `/opt/backup-mysql.sh`
2. Adjust the variables inside the script to match the setup
3. Allow execution `chmod +x /opt/backup-mysql.sh`
4. Add the cronjob `crontab -e`
5. Add and save: `0 1 * * * /opt/backup-mysql.sh`

## Restore a backup
1. Copy `src/backup-restore-files.sh` to `/opt/backup-restore-files.sh`
2. Adjust the variables inside the script to match the setup
3. Allow execution `chmod +x /opt/backup-restore-files.sh`
4. Running `/opt/backup-restore-files.sh` will restore the latest backup to `/01_data/backup-restore/`

## Decompress data
A zstandard archive
```zstd -d example1.txt.zst```
A tarball compressed with zstandard
```tar -I zstd -xvf example.tar.zst```

## Additional literature
- https://miketabor.com/how-i-backup-my-vps-servers-to-aws-s3-bucket/
- https://gridscale.io/community/tutorials/backup-s3-duplicity/
- https://easyengine.io/tutorials/backups/duplicity-amazon-s3/
- https://blog.programster.org/backing-up-s3-bucket-with-duplicity
- https://whatsecurity.nl/secure_backups_using_duplicity_and_amazon_s3.html
- https://linuxconfig.org/how-to-install-and-use-zstd-compression-tool-on-linux