#!/bin/bash
set -x  # Enable command tracing for debugging
npm install -g cdktf-cli@0.20.7
npm ci || { echo "Error: npm ci failed"; exit 1; }
rm -rf .gen
cdktf get || { echo "Error: cdktf get failed"; exit 1; }
npm run synth || { echo "Error: npm run synth failed"; exit 1; }
cp import-commands.sh cdktf.out/stacks/prod-e/ || { echo "Error: Failed to copy import-commands.sh to cdktf.out/stacks/prod-e/"; exit 1; }
cd cdktf.out/stacks/prod-e || { echo "Error: Failed to cd into cdktf.out/stacks/prod-e"; exit 1; }
terraform init -upgrade || { echo "Error: terraform init -upgrade failed"; exit 1; }
sh ./import-commands.sh > import-commands.log 2>&1 || { echo "Error: Failed to run import-commands.sh"; exit 1; }
cat import-commands.log
cd ../../..
npm test || { echo "Error: npm test failed"; exit 1; }
echo "Navigating to infrastructure/lambda..."
cd infrastructure/lambda || { echo "Error: Failed to cd into infrastructure/lambda"; exit 1; }
echo "Removing any existing backup.zip..."
rm -f backup.zip || { echo "Error: Failed to remove backup.zip"; exit 1; }
echo "Creating backup.zip from backup.js..."
if [ ! -f backup.js ]; then echo "Error: backup.js not found in infrastructure/lambda"; exit 1; fi
zip -j backup.zip backup.js || { echo "Error: Failed to create backup.zip"; exit 1; }
echo "Listing backup.zip..."
ls -la backup.zip || { echo "Error: backup.zip not found after creation"; exit 1; }
echo "Inspecting backup.zip contents..."
unzip -l backup.zip || { echo "Error: Failed to inspect backup.zip"; exit 1; }
echo "Copying backup.zip to root as dummy-backup.zip..."
cp backup.zip ../../dummy-backup.zip || { echo "Error: Failed to copy backup.zip to dummy-backup.zip"; exit 1; }
echo "Listing dummy-backup.zip in root..."
ls -la ../../dummy-backup.zip || { echo "Error: dummy-backup.zip not found in root"; exit 1; }
cd ../../
echo "Copying dummy-backup.zip to cdktf.out/stacks/prod-e/..."
cp dummy-backup.zip cdktf.out/stacks/prod-e/ || { echo "Error: Failed to copy dummy-backup.zip to cdktf.out/stacks/prod-e/"; exit 1; }
echo "Running cdktf deploy from root directory..."
cdktf deploy --auto-approve || { echo "Error: cdktf deploy failed"; exit 1; }
