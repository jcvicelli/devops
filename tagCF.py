# /usr/local/bin/python3

import boto3
from botocore.exceptions import ClientError

print('starting cloudfront tagging...')

cf = boto3.client('cloudfront')
cfList = cf.list_distributions()

for distribution in cfList['DistributionList']['Items']:
    tags = cf.list_tags_for_resource(Resource=distribution['ARN'])
    tagsItems = tags['Tags']['Items']

    if len(tagsItems) == 0:
        print(distribution['Id'] + " does not have tags, adding tags...")
        response = cf.tag_resource(
            Resource=distribution['ARN'],
            Tags={
                'Items': [
                    {
                        'Key': 'taggedBy',
                        'Value': 'jeansScript'
                    },
                    {
                        'Key': 'cost-environment',
                        'Value': 'dev'
                    },
                    {
                        'Key': 'cost-system',
                        'Value': 'cloudfront'
                    },
                    {
                        'Key': 'cost-team',
                        'Value': 'devops'
                    },
                ]
            }
        )


print('done')
