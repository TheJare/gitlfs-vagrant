#!/usr/bin/env bash

set -e

# provisioner script is run from /tmp not the shared folder,
# so we just hardcode instead of finding there the shared folder is
LOCALDIR="/vagrant"
# "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# these are normally passed via Vagrantfile to environment
# but if you run this on bare metal they need to be reset
GITLFS_HOSTNAME=${GITLFS_HOSTNAME:-127.0.0.1}
GITLFS_PORT=${GITLFS_PORT:-8443}
GITLFS_ROOT=${GITLFS_ROOT:-/var/gitlfs}
GITLFS_ADMIN_USER=${GITLFS_ADMIN_USER:-admin}
GITLFS_ADMIN_PASSWORD=${GITLFS_ADMIN_PASSWORD:-admin}

export DEBIAN_FRONTEND=noninteractive

fatal()
{
    echo "fatal: $@" >&2
    exit 1
}

check_for_root()
{
    if [[ $EUID != 0 ]]; then
        fatal "need to be root"
    fi
}

sanity_check() {
    case $GITLFS_ROOT in
        ""|/) fatal "root path for gitlfs can't be empty";;
        *\ *) fatal "root path for gitlfs can't contain whitespace";;
    esac
}

check_for_root
sanity_check

# install tools to automate this install
apt-get -y update
# apt-get -y install curl

# install the few dependencies we have
apt-get -y install openssl

# Tools to serve git via https via fcgi
apt-get -y install nginx git git-core fcgiwrap

# generate ssl keys
apt-get -y install ca-certificates ssl-cert
make-ssl-cert generate-default-snakeoil --force-overwrite

# Prepare git environment
echo "Setting up git repo folder inside $GITLFS_ROOT/git"
mkdir $GITLFS_ROOT
mkdir $GITLFS_ROOT/git
mkdir $GITLFS_ROOT/lfs
DEFAULT_AUTH_PW=$(openssl passwd -crypt $GITLFS_ADMIN_PASSWORD)
DEFAULT_AUTH="$GITLFS_ADMIN_USER:$DEFAULT_AUTH_PW"
printf "$DEFAULT_AUTH\n" >> $GITLFS_ROOT/htpasswd

wget https://github.com/TheJare/lfs-test-server/releases/download/v0.5.0-TheJare/lfs-test-server -nv -O "$GITLFS_ROOT/lfs-test-server" 2>&1

chown -R www-data:www-data $GITLFS_ROOT

# Create a simple test repo
sudo -u www-data git init --bare "$GITLFS_ROOT/git/$GITLFS_ADMIN_USER/test.git"

# Set up the web server to accept and forward git requests
sed -e "s,/var/gitlfs,${GITLFS_ROOT}," "$LOCALDIR/gitlfs.nginx" > /etc/nginx/sites-enabled/gitlfs

# Set up the lfs server and daemon service
sed -e "s,GITLFS_ADMIN_USER,${GITLFS_ADMIN_USER}," -e "s,GITLFS_ADMIN_PASSWORD,${DEFAULT_AUTH_PW}," -e "s,GITLFS_ROOT,$GITLFS_ROOT," "$LOCALDIR/lfs-server.sh.tmpl" > /usr/sbin/lfs-server.sh

chmod +x /usr/sbin/lfs-server.sh
chmod +x "$GITLFS_ROOT/lfs-test-server"

cp "$LOCALDIR/lfs_server.service" /lib/systemd/system/
systemctl enable lfs_server.service 2>&1
systemctl start lfs_server

service nginx reload

# Create the default user in the lfs server
curl -s -S -d name=$GITLFS_ADMIN_USER -d password=$GITLFS_ADMIN_PASSWORD -u "$DEFAULT_AUTH" http://localhost:9999/mgmt/add

# done
echo ""
echo "Done!"
echo "You can access the git server via git -c http.sslVerify=false [...git command...]"
echo "Default git user is '$GITLFS_ADMIN_USER' with password '$GITLFS_ADMIN_PASSWORD'"
echo "Inside this VM the url will be https://localhost/git/<<user>>/<<repo>>"
echo "From the VM host the url will be https://localhost:$GITLFS_PORT/git/<<user>>/<<repo>>"
echo ""
echo "To begin, try:"
echo "  git -c http.sslVerify=false clone https://localhost:$GITLFS_PORT/git/$GITLFS_ADMIN_USER/test.git"
echo "  cd test"
echo "  git lfs track '*.zip'"
echo "  echo test > test.zip"
echo "  git add ."
echo "  git commit -m 'first commit'"
echo "  git -c http.sslVerify=false push origin master"
