#!/usr/bin/python3

import os
import boto3
import sys

if len(sys.argv) > 3:

    fileName = sys.argv[1]
    keyName = sys.argv[2]
    bucketUpload = sys.argv[3]

    if os.path.isfile(fileName):

        s3 = boto3.resource(service_name='s3')
        s3.meta.client.upload_file(Filename=fileName,
                                   Bucket=bucketUpload, Key=keyName, ExtraArgs={'ACL': 'authenticated-read'})

    else:
        print(fileName, "not found or is not a valid file.")

else:
    print("Usage: s3upload.py file.sql.gz keyname.sql.gz s3_bucket_name")
