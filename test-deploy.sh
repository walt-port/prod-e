#!/bin/bash
set -e

# Install necessary packages
npm install -g cdktf-cli
npm ci

# Get dependencies
cdktf get

# Clean and synthesize
rm -rf cdktf.out
npm run synth

# Copy and execute import script
chmod +x import-commands.sh
cp import-commands.sh cdktf.out/stacks/prod-e/
cd cdktf.out/stacks/prod-e/
../../import-commands.sh > import-commands.log 2>&1 || echo "Import commands completed with some errors"
terraform init -upgrade
cd ../../..

# Create dummy backup.zip file
mkdir -p node_modules/backup
cp infrastructure/lambda/backup.js node_modules/backup/
cd node_modules/backup
zip -r backup.zip .
cp backup.zip ../../
cd ../../
mv backup.zip dummy-backup.zip
cp dummy-backup.zip cdktf.out/stacks/prod-e/

# Deploy
cdktf deploy --auto-approve
