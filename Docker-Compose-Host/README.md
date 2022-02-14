# Create a docker host from scratch
I assume we start with an ubuntu server.
All shell commands have to be executed as "root" user.

## Before we start

```
mkdir -p /00_work \
    && mkdir -p /01_data \
    && chmod 777 /00_work \
    && chmod 755 /01_data \
    && chmod +x /opt/boot.sh \
    && chmod +x /opt/docker-login.sh
```

ensure that all files inside the "src" directory are copied to the 
root (/) directory of the webserver.

To use the "nano" editor as default run and ensure that you 
select the number for `/bin/nano`

```
update-alternatives --config editor
``` 

Let's give it a name
```
hostnamectl set-hostname server.example.org \
    && nano /etc/hosts
```
In the editor, replace any occurrence of the existing computer name with your new one.

## Create users and basic groups
Change root password (Use "echo 'pi:newpassword' | sudo chpasswd" for unattended installation)
```
passwd
```

```
groupadd sshusers \
    && groupadd nginx \
    && groupadd docker
```

```
useradd admin -m -r -g users -G sshusers,sudo -d /01_data/home/admin -s /bin/bash
```

Set a strong password for the admin user
```
passwd admin
```

Add the public key when the nano window opens
```
mkdir -p /01_data/home/admin/.ssh \
    && chmod -R 755 /01_data/home/admin/.ssh \
    && touch /01_data/home/admin/.ssh/authorized_keys \
    && chmod 600 /01_data/home/admin/.ssh/authorized_keys \
    && nano /01_data/home/admin/.ssh/authorized_keys \
    && chown -R admin /01_data/home/admin/.ssh
```

This is only required if you want a specific "deployment" user
```
useradd deployment -m -r -g docker -G sshusers -d /01_data/home/deployment -s /bin/bash
```

## Configure and secure SSH

Clean up config
```
sudo sed -i -r -e '/^#|^$/ d' /etc/ssh/sshd_config
```

```
nano /etc/ssh/sshd_config
```

Merge remaining code with this:
```
########################################################################################################
# start settings from https://infosec.mozilla.org/guidelines/openssh#modern-openssh-67 as of 2019-01-01
########################################################################################################

# Supported HostKey algorithms by order of preference.
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key

KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256

Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com

# LogLevel VERBOSE logs user's key fingerprint on login. Needed to have a clear audit track of which key was using to log in.
LogLevel VERBOSE

# Use kernel sandbox mechanisms where possible in unprivileged processes
# Systrace on OpenBSD, Seccomp on Linux, seatbelt on MacOSX/Darwin, rlimit elsewhere.
# Note: This setting is deprecated in OpenSSH 7.5 (https://www.openssh.com/txt/release-7.5)
# UsePrivilegeSeparation sandbox

########################################################################################################
# end settings from https://infosec.mozilla.org/guidelines/openssh#modern-openssh-67 as of 2019-01-01
########################################################################################################

# don't let users set environment variables
PermitUserEnvironment no

# Log sftp level file access (read/write/etc.) that would not be easily logged otherwise.
Subsystem sftp  internal-sftp -f AUTHPRIV -l INFO

# only use the newer, more secure protocol
Protocol 2

# disable X11 forwarding as X11 is very insecure
# you really shouldn't be running X on a server anyway
X11Forwarding no

# disable port forwarding
AllowTcpForwarding no
AllowStreamLocalForwarding no
GatewayPorts no
PermitTunnel no

# don't allow login if the account has an empty password
PermitEmptyPasswords no

# ignore .rhosts and .shosts
IgnoreRhosts yes

# verify hostname matches IP
UseDNS yes

Compression no
TCPKeepAlive no
AllowAgentForwarding no
PermitRootLogin no

# don't allow .rhosts or /etc/hosts.equiv
HostbasedAuthentication no
```

Add or modify values
```
AllowGroups sshusers
ClientAliveCountMax 0
ClientAliveInterval 300
LoginGraceTime 30
MaxAuthTries 2
MaxSessions 2
MaxStartups 2
PasswordAuthentication no
Port 22
```

Restart the server (Make sure to have at least 2 connections open!)
```
service sshd restart
```

Remove short moduli [https://infosec.mozilla.org/guidelines/openssh#modern-openssh-67]
```
sudo awk '$5 >= 3071' /etc/ssh/moduli | sudo tee /etc/ssh/moduli.tmp
sudo mv /etc/ssh/moduli.tmp /etc/ssh/moduli
```

## Register boot script
```
crontab -e
```

add and save:
```
@reboot /opt/boot.sh
```

## Setup email redirect (optional)

Create a new gmail account to send the mails through
(I recommend you create one specific for this server. That way if your server is compromised,
the bad-actor won't have any passwords for your primary account.)
Note: Less secure apps must be enabled
```
apt-get install -y ssmtp mailutils \
    && nano /etc/ssmtp/ssmtp.conf
```

Modify the configuration to look somewhat like this:
```
hostname=hostname.your.domain

# root is the person who gets all mail for userids < 1000
root=your@email.com

# Here is the gmail configuration (or change it to your private smtp server)
mailhub=smtp.gmail.com:587
AuthUser=your@gmail.com
AuthPass=yourGmailPass # No special chars #:=$1@... and no Spaces!
UseTLS=YES
UseSTARTTLS=YES
```

## Install log watch (optional)

```
apt-get install -y logwatch net-tools
```

```
nano /etc/cron.daily/00logwatch
```

Edit the logwatch cronjob (the line below #execute), to send the mail:
```
/usr/sbin/logwatch --output mail --format html --mailto root --range yesterday --service all
```

## Install webmin (optional) 

Edit the "/01_data/iptables.conf" file and add this:
```
-A FILTERS -m state --state NEW -m tcp -p tcp --dport 2096 -j ACCEPT
```

before:
```
-A FILTERS -j DROP
```

```
/sbin/iptables-restore -n /01_data/iptables.conf
```

```
cd /root \
    && wget https://download.webmin.com/jcameron-key.asc \
    && cat jcameron-key.asc | gpg --dearmor >/etc/apt/trusted.gpg.d/jcameron-key.gpg \
    && add-apt-repository 'deb https://download.webmin.com/download/repository sarge contrib' \
    && apt-get install apt-transport-https \
    && apt-get update \
    && apt-get install webmin
```

Modify the port number to "2096" instead "10000"
```
nano /etc/webmin/miniserv.conf \
    && /etc/init.d/webmin restart
```

Open Webmin in a browser: https://server.example.org:2096 (I suggest using cloudflare for this)
In the UI: 
1. Webmin -> Webmin Users
2. Create a new priviledged user
3. Use a random username
4. Create a STRONG password
5. Real name "Admin"
6. Available Webmin modules 
7. "Select all"
8. "Create"
9. Webmin -> Webmin Configuration -> Authentication
10. Block hosts with more than 3 failed logins for 900 seconds
11. Block users with more than 3 failed logins for 60 seconds.
12. Record logins and logouts in utmp?
13. "Save"
14. Wait for restart...
15. Webmin -> Webmin Configuration -> Two-Factor Authentication
16. Authentication provider -> Google Authenticator
17. "Save" 
18. (Optional) install perl module if required
19. Wait for restart...
20. Webmin -> Webmin Users -> the "Admin" user name you set
21. Security and limits options
22. Two-factor authentication type -> Enable Two-Factor for user
23. Logout and check if a login with the "Admin" user is possible
24. Webmin -> Webmin Users
25. Select "root"
26. "Delete selected"
27. Webmin -> Webmin Configuration -> Ports and Addresses
28. "Open new ports on firewall?" -> off
29. "Accept IPv6 connections?" -> no
30. "Listen for broadcasts on UDP port" -> Don't listen
31. "Web server hostname" -> server.example.org
32. Webmin -> Webmin Configuration -> Sending Email
33. Webmin URL for use in email -> https://server.example.org:2096

### Install docker and docker-compose
```
mkdir -p /01_data/persistent \
    && mkdir -p /02_docker \
    && chown -R root:docker /01_data/persistent \
    && chown -R root:docker /02_docker
```

```
apt-get update \
    && apt-get install -yq \
        apt-transport-https \
        ca-certificates \
        curl \
        unzip \
        nano \
        gnupg2 \
        software-properties-common
```

```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

```
echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
```

tzdata is required by docker, we install it here, because this way we can control the installation,
if we would omit this, an interactive shell would block the automated process
```
DEBIAN_FRONTEND=noninteractive \
    && TZ=Europe/Berlin \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && apt-get install -y tzdata
```

```
apt-get update && apt-get install -yq docker-ce docker-ce-cli containerd.io
```

**IMPORTANT: UPDATE THE VERSION HERE**
```
export DOCKER_COMPOSE_VERSION="v2.2.2" \
    && curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose
```

```
/opt/boot.sh
```

Start the cleanup application
```
chown -R root:docker /02_docker/cleanup \
    && chmod -R 740 /02_docker/cleanup \
    && cd /02_docker/cleanup \
    && docker-compose up -d
```

### Create a nginx reverse-proxy
Copy the contents of /opt-src/nginx to /02_docker/nginx on the server.
See the [official documentation](https://hub.docker.com/r/jwilder/nginx-proxy) for additional setup instructions 

```
mkdir -p /01_data/ssl \
    && chown -R root:docker /01_data/ssl \
    && chmod -R 640 /01_data/ssl
```

```
chown -R root:docker /02_docker/nginx \
    && chmod -R 640 /02_docker/nginx \
    && cd /02_docker/nginx \
    && docker-compose up -d
```

#### A word on SSL
Wildcard certificates and keys should be named after the domain name with a .crt and .key extension. 
For example VIRTUAL_HOST=foo.bar.com would use cert name bar.com.crt and bar.com.key.

#### An app example

```
version: "2"

services:
    app:
        restart: always
        image: jwilder/whoami
        expose:
            - 80
        networks:
            - web_net
            - mariadb_net # If maria-db should be available in the container
        environment:
            - VIRTUAL_HOST=service.example.org,www.service.example.org
            - VIRTUAL_PORT=8000 # If NOT port 80 should be used
            - CERT_NAME=example.org # If you want to use a custom certificate
        logging: # This option is critical! It activates docker's log-rotation and avoids storage overflow
            options:
                max-size: "128m"
                max-file: "3"

networks:
  web_net:
    external: true
  mariadb_net: # If maria-db should be available in the container
    external: true
```

### Create a mysql (maria-db) service
Copy the contents of /opt-src/mariadb to /02_docker/mariadb on the server

**Set a secure root password in .env**

Edit the /opt/boot.sh add a new network creation command:
```
docker network create -d bridge mariadb_net
```

after the line:
```
docker network create -d bridge web_net
```

```
/opt/boot.sh
```

Start the database
```
cd /02_docker/mariadb \
    && docker-compose up -d
```

#### Install mariadb client on the host (optional)
```
cd /00_work \
    && wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup \
    && echo "fd3f41eefff54ce144c932100f9e0f9b1d181e0edd86a6f6b8f2a0212100c32c mariadb_repo_setup" \
    && chmod +x mariadb_repo_setup \
    && ./mariadb_repo_setup \
    && apt-get update \
    && apt-get install mariadb-client
```

#### If you want to use Heidi-SQL (optional)
```
nano /etc/ssh/sshd_config
```
Change ```PermitTunnel no``` to ```PermitTunnel yes```
and ```AllowTcpForwarding `no```` to ```AllowTcpForwarding yes```

Restart the ssh service
```
service ssh restart
```

## Additional literature

* https://github.com/imthenachoman/How-To-Secure-A-Linux-Server#disable-root-login
* https://www.howtogeek.com/443156/the-best-ways-to-secure-your-ssh-server/
* https://forum.seafile.com/t/tutorial-for-logwatch-on-debian-for-nginx-with-postfix-configuration-as-satellite-system/123