#!/bin/bash
set -e

cd $PATH_TO_REDMINE

if [ -L "$PATH_TO_PLUGINS/$PLUGIN" ]; then
    rm "$PATH_TO_PLUGINS/$PLUGIN"
fi
ln -s "$PATH_TO_PLUGIN" "$PATH_TO_PLUGINS/$PLUGIN"

cp $PATH_TO_PLUGINS/$PLUGIN/.travis/database.yml config/database.yml
