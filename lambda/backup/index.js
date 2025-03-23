const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const fs = require('fs').promises;

const s3 = new S3Client({ region: process.env.AWS_REGION || 'us-west-2' });

exports.handler = async () => {
  const bucket = process.env.BACKUP_BUCKET || 'prod-e-grafana-backups';
  try {
    const files = await fs.readdir('/mnt/efs');
    for (const file of files) {
      const content = await fs.readFile(`/mnt/efs/${file}`);
      await s3.send(new PutObjectCommand({
        Bucket: bucket,
        Key: file,
        Body: content,
      }));
    }
    return { statusCode: 200, body: 'Backup complete' };
  } catch (err) {
    console.error('Backup failed:', err);
    return { statusCode: 500, body: 'Backup failed: ' + err.message };
  }
};
