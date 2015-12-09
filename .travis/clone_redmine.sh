#!/bin/bash
set -e

export PATH_TO_PLUGIN=$(pwd)
export PATH_TO_REDMINE=$(pwd)/$REDMINE

case $REDMINE_VERSION in
  1.4.*)  export PATH_TO_PLUGINS=./vendor/plugins # for redmine < 2.0
          export GENERATE_SECRET=generate_session_store
          export MIGRATE_PLUGINS=db:migrate_plugins
          export REDMINE_TARBALL=https://github.com/redmine/redmine/archive/$REDMINE_VERSION.tar.gz
          ;;
  2.*|3.*)
          export PATH_TO_PLUGINS=./plugins # for redmine >= 2.0
          export GENERATE_SECRET=generate_secret_token
          export MIGRATE_PLUGINS=redmine:plugins:migrate
          export REDMINE_TARBALL=https://github.com/redmine/redmine/archive/$REDMINE_VERSION.tar.gz
          ;;
  master) export PATH_TO_PLUGINS=./plugins
          export GENERATE_SECRET=generate_secret_token
          export MIGRATE_PLUGINS=redmine:plugins:migrate
          export REDMINE_GIT_REPO=git://github.com/redmine/redmine.git
          export REDMINE_GIT_TAG=master
          ;;
  *)      echo "Unsupported platform $REDMINE_VERSION"
          exit 1
          ;;
esac

if [ ! "$VERBOSE" = "yes" ]; then
    QUIET=--quiet
fi
if [ -n "${REDMINE_GIT_TAG}" ]; then
    git clone -b $REDMINE_GIT_TAG --depth=100 $QUIET $REDMINE_GIT_REPO $PATH_TO_REDMINE
    cd $PATH_TO_REDMINE
    git checkout $REDMINE_GIT_TAG
else
    mkdir -p $PATH_TO_REDMINE
    wget $REDMINE_TARBALL -O- | tar -C $PATH_TO_REDMINE -xz --strip=1 --show-transformed -f -
fi

# prepare plugin for tests
cd $PATH_TO_REDMINE

if [ -L "$PATH_TO_PLUGINS/$PLUGIN" ]; then
    rm "$PATH_TO_PLUGINS/$PLUGIN"
fi
ln -s "$PATH_TO_PLUGIN" "$PATH_TO_PLUGINS/$PLUGIN"

cp $PATH_TO_PLUGINS/$PLUGIN/.travis/database.yml config/database.yml
