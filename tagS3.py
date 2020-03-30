# /usr/local/bin/python3

import boto3
from botocore.exceptions import ClientError

print('starting...')

s3 = boto3.client('s3')
s3_re = boto3.resource('s3')

# for bucket in s3_re.buckets.all():
for bucket in s3_re.buckets.all():
    s3_bucket = bucket
    s3_bucket_name = s3_bucket.name
    bucket_tagging = s3_re.BucketTagging(s3_bucket_name)

    try:
        response = s3.get_bucket_tagging(Bucket=s3_bucket_name)
    except ClientError:
        print(s3_bucket_name + " does not have tags, adding tags...")

        response = bucket_tagging.put(
            Tagging={
                'TagSet': [
                    {
                        'Key': 'cost-environment',
                        'Value': 'dev'
                    },
                    {
                        'Key': 'cost-system',
                        'Value': 's3'
                    },
                    {
                        'Key': 'cost-team',
                        'Value': 's3'
                    },
                ]
            }
        )

print('done')
