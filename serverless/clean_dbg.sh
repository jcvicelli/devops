#!/bin/bash

CHEF_REPO='chef-repo'
CODECOMMIT_KEY='123'

rm -rf ${CHEF_REPO}

git clone ssh://abc/v1/repos/${CHEF_REPO}

cd ${CHEF_REPO}

BAGS=(`knife vault show stack -M client`)

STACKS=(`aws --region us-east-1 --profile abc cloudformation list-stacks | jq '.StackSummaries[] | select(.StackStatus!="DELETE_COMPLETE") | .StackName'`)

for b in "${BAGS[@]}" 
do 
    # echo "*******Bag $b"
    # search bags in stacks, if not found, delete it
    FOUND='n'
    for s in "${STACKS[@]}"
    do
        stack=${s//\"}
        #echo "*******Stack $stack"
        
        if [ "$stack" == "$b" ] ; then
            echo "Found databag $b on stack $stack"
            FOUND='y'
        fi
    done

    if [ "$FOUND" == "n" ] ; then
        echo "Databag $b not found on any stack, deleting..."
        #delete from git
        if [ -e data_bags/stack${b}]; then 
            rm -f data_bags/stack/${b}*
        fi

        #delete from chef
        knife vault delete stack $b -M client -y
    fi
    
done 

# commit and push all the changes
git add *
git commit -am "remove stacks not in use"
git push

exit 0