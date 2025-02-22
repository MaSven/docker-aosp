#!/bin/bash
set -e

# This script designed to be used a docker ENTRYPOINT "workaround" missing docker
# feature discussed in docker/docker#7198, allow to have executable in the docker
# container manipulating files in the shared volume owned by the USER_ID:GROUP_ID.
#
# It creates a user named `aosp` with selected USER_ID and GROUP_ID (or
# 1000 if not specified).

# Example:
#
#  docker run -ti -e USER_ID=$(id -u) -e GROUP_ID=$(id -g) imagename bash
#

# Reasonable defaults if no USER_ID/GROUP_ID environment variables are set.
if [ -z ${USER_ID+x} ]; then USER_ID=1000; fi
if [ -z ${GROUP_ID+x} ]; then GROUP_ID=1000; fi

# ccache
export CCACHE_DIR=/tmp/ccache
export USE_CCACHE=1

msg="docker_entrypoint: Creating user UID/GID [$USER_ID/$GROUP_ID/$GROUP_NAME]" && echo $msg
groupadd -g $GROUP_ID -r $GROUP_NAME && \
useradd -u $USER_ID  -r -m -g $GROUP_NAME $USER_NAME
echo "$msg - done"

msg="docker_entrypoint: Copying .gitconfig and .ssh/config to new user home" && echo $msg
cp /root/.gitconfig /home/$USER_NAME/.gitconfig && \
chown $USER_NAME:$GROUP_NAME /home/$USER_NAME/.gitconfig && \
mkdir -p /home/$USER_NAME/.ssh && \
cp /root/.ssh/config /home/$USER_NAME/.ssh/config && \
chown $USER_NAME:$GROUP_NAME -R /home/$USER_NAME/.ssh &&
echo "$msg - done"

msg="docker_entrypoint: Creating /tmp/ccache and /$USER_NAME directory" && echo $msg
mkdir -p /tmp/ccache /$USER_NAME
chown $USER_NAME:$GROUP_NAME /tmp/ccache /$USER_NAME
echo "$msg - done"

echo ""

# Default to 'bash' if no arguments are provided
args="$@"
if [ -z "$args" ]; then
  args="bash"
fi

# Execute command as `$USER_NAME` user
export HOME=/home/$USER_NAME
exec sudo -E -u $USER_NAME $args
