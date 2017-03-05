# Git LFS server

This repo contains a full Vagrant setup and install script to build a local VM running a git server and a matching git-lfs server both under HTPPS via nginx.

This will not install the git lfs client on your host. Read the docs at [https://github.com/git-lfs/git-lfs](https://github.com/git-lfs/git-lfs) for instructions on client setup and general operation.

## Instructions

Clone this repo and run `vagrant up`. If all goes well, the last files of the log will show you how to access the local server. The default should be something like:

`git -c http.sslVerify=false clone https://localhost:8443/git/master/test.git`

SSL verification must be turned off because the server uses self-signed certificates. A production server would have the real thing.

The default user is called "admin" with password "admin". That's also the root user of the lfs server.

## Notes

- There are a few configuration variables you can customize in the Vagrantfile.
- Uses a modified version of the reference lfs test server implementation from Github, which is somewhat old and not validated for production. My version is forked at [https://github.com/TheJare/lfs-test-server](https://github.com/TheJare/lfs-test-server)
- This lfs server does not support locking or any fancy git lfs 2.0 features.
- Creating new users and repos must be done manually inside the VM. Remember to add new users to both the web server auth file (typically at `var/gitlfs/htpasswd`) and to the lfs server. The `install.sh` script is the best place to see how this is done until I document this better.
- The lfs server runs under the www-data user. Not very pretty.
- This is not yet very tested.
