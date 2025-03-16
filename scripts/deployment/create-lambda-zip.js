/**
 * Lambda Deployment Package Creator
 *
 * This script creates a deployment package (ZIP file) for AWS Lambda functions.
 * It packages source code along with any node_modules dependencies.
 *
 * Usage:
 *   node create-lambda-zip.js <source_dir> <output_dir> <function_name>
 *
 * Arguments:
 *   source_dir:   Path to the directory containing Lambda function code
 *   output_dir:   Directory where the ZIP file will be saved
 *   function_name: Name of the Lambda function (used for the ZIP filename)
 *
 * Example:
 *   node create-lambda-zip.js ./src/lambda/backup infrastructure/lambda backup-function
 */

const fs = require('fs');
const path = require('path');
const archiver = require('archiver');

// Process command line arguments
const args = process.argv.slice(2);

if (args.length < 3) {
  console.error('Error: Missing required arguments');
  console.error('Usage: node create-lambda-zip.js <source_dir> <output_dir> <function_name>');
  process.exit(1);
}

const sourceDir = args[0];
const outputDir = args[1];
const functionName = args[2];

// Validate source directory
if (!fs.existsSync(sourceDir)) {
  console.error(`Error: Source directory '${sourceDir}' does not exist`);
  process.exit(1);
}

// Create output directory if it doesn't exist
if (!fs.existsSync(outputDir)) {
  try {
    fs.mkdirSync(outputDir, { recursive: true });
  } catch (err) {
    console.error(`Error: Failed to create output directory: ${err.message}`);
    process.exit(1);
  }
}

// Create output filename
const outputFile = path.join(outputDir, `${functionName}-code.zip`);

// Create a file to stream archive data to
const output = fs.createWriteStream(outputFile);
const archive = archiver('zip', {
  zlib: { level: 9 }, // Maximum compression
});

// Listen for all archive data to be written
output.on('close', function () {
  console.log(`Lambda code ZIP file created at ${outputFile}`);
  console.log(`To deploy this Lambda function, use:`);
  console.log(`aws lambda update-function-code --function-name prod-e-backup \\`);
  console.log(`  --zip-file fileb://${outputFile}`);
});

// Listen for warnings
archive.on('warning', function (err) {
  if (err.code === 'ENOENT') {
    console.warn(`Warning: ${err.message}`);
  } else {
    throw err;
  }
});

// Listen for errors
archive.on('error', function (err) {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});

// Pipe archive data to the file
archive.pipe(output);

// Add source directory contents to the archive
archive.directory(sourceDir, false);

// Check if node_modules exists in source directory and add it
const nodeModulesPath = path.join(sourceDir, 'node_modules');
if (fs.existsSync(nodeModulesPath)) {
  archive.directory(nodeModulesPath, 'node_modules');
}

// Finalize the archive
archive.finalize();
