import boto3
import logging
from pygit2 import clone_repository

LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.INFO)

def clean_dbg(event, context):
    """ Cleanup dbg that are not being used """

    # get a list of files from git

    # repo_url = 'git://github.com/libgit2/pygit2.git'
    # repo_path = '/path/to/create/repository'
    # repo = clone_repository(repo_url, repo_path)


    # get a list of stacks from aws
    cf = boto3.client('cloudformation')
    paginator = cf.get_paginator('list_stacks')
    page_iterator = paginator.paginate(StackStatusFilter=['CREATE_COMPLETE', 'UPDATE_COMPLETE'])

    stack_names = []
    for page in page_iterator:
        stack = page['StackSummaries']
        for output in stack:
            stack_names.append(output['StackName'])

    print('abc' in stack_names)
    

    # compare the items
    # if stack not found, delete databag from git and chef

