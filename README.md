# Docker Compose Host Setup
This repository contains a set of instructions on how to setup a generic docker compose host
on the server infrastructure of a client. The host will run docker images, have a global mysql container
instance as well as a nginx reverse proxy.

1. start with [Docker-Compose-Host](Docker-Compose-Host/README.md)
2. work your way to [Backups to S3](Backup-To-S3/README.md)
3. you can find commonly used linux commands in the [command list](Commands/README.md)

## Images and deployment
You can use any valid docker-compose.yml to boot up a service, or use [our docker base images](https://github.com/labor-digital/docker-base-images) to create an application.
After you are done, use our [bitbucket pipeline image](https://github.com/labor-digital/bitbucket-pipeline-images#deploy-docker-to-compose-host) to deploy your app to production.
