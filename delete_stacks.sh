#!/bin/bash

    #BRANCHES=(`git branch -r | grep ABCDE | awk -F\/ '{printf("%s\n", $2)}'`)
    BRANCHES=(`git ls-remote -h git@github.com:jean/jean.git | grep ABCDE | awk -F\/ '{printf("%s\n", $3)}'`)
    STACKS=(`aws --region us-east-1 --profile deploy cloudformation list-stacks | jq '.StackSummaries[] | select(.StackStatus!="DELETE_COMPLETE") | select(.StackName | contains("ABCDE")) | select(.StackName | contains("jean")) | .StackName'`)

    for s in "${STACKS[@]}" 
    do 
        stack=${s//-jean}
        stack=${stack//\"}
        #echo "*******Stack $stack"
        # search stacks in branches, if not found, delete it
        FOUND='n'
        for b in "${BRANCHES[@]}"
        do
            #echo "*******Branch $b"
            
            if [ "$stack" == "$b" ] ; then
                echo "Found stack $stack on branch $b"
                FOUND='y'
            fi
        done

        if [ "$FOUND" == "n" ] ; then
            echo "Stack $stack not found on any branch, deleting..."
            aws --region us-east-1 --profile deploy cloudformation delete-stack --stack-name ${stack}-jean
        fi
        
    done 
    exit 0