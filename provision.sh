#!/bin/bash

set -e

PROFILE=${HOME}/.bash_profile
PROMPT='\[\e[1;36m\]\h \w \$ \[\e[0m\]'
BIN=/opt/bin

#
# Shell Prompt
#
if [[ ! -f $PROFILE ]]; then
  touch $PROFILE
fi

if grep -q '^export PS1=.*$' $PROFILE; then
  sed -i '/^export PS1=.*$/d' $PROFILE
fi

echo "export PS1=\"${PROMPT}\"" >> $PROFILE

#
# Install Wocker CLI
#
sudo mkdir -p $BIN
sudo wget -q -O ${BIN}/wocker https://raw.githubusercontent.com/wckr/wocker-cli/master/wocker
sudo chmod +x ${BIN}/wocker

sudo sed -i 's/-p 80:80 -p 3306:3306//g' ${BIN}/wocker

#
# Pull the Wocker image & create the first container
#
docker pull wocker/wocker:latest
