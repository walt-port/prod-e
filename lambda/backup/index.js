const AWS = require('aws-sdk');
const fs = require('fs');
const s3 = new AWS.S3();

exports.handler = async () => {
  const files = fs.readdirSync('/mnt/efs');
  for (const file of files) {
    const content = fs.readFileSync('/mnt/efs/' + file);
    await s3
      .putObject({
        Bucket: 'prod-e-grafana-backups',
        Key: file,
        Body: content,
      })
      .promise();
  }
  return { statusCode: 200, body: 'Backup complete' };
};
