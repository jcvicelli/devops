#!/bin/bash

set -e

FEATURE_BRANCHES=(`git ls-remote -h https://$USERNAME:$GITHUB_TOKEN@github.com/jean/jean-search.git | grep 'feature/' | awk -F '/' '{printf("%s\n",  "feature-" $4)}'`)
HOTFIX_BRANCHES=(`git ls-remote -h https://$USERNAME:$GITHUB_TOKEN@github.com/jean/jean-search.git | grep 'hotfix/' | awk -F '/' '{printf("%s\n", "hotfix-" $4)}'`)

BRANCHES+=("${HOTFIX_BRANCHES[@]}")
BRANCHES+=("${FEATURE_BRANCHES[@]}")

DEPLOYMENTS=(`helm3 list --namespace search-jean | grep 'jean-search-feature-\|jean-search-hotfix-' | awk '{printf("%s\n", $1)}'`)

for d in "${DEPLOYMENTS[@]}"
do
    deployment=${d//jean-search-}
    deployment=`echo $deployment | awk '{printf tolower($0)}'`

    echo "*******Deployment $deployment"
    # search deployments in branches, if not found, delete it
    FOUND='n'
    for b in "${BRANCHES[@]}"
    do
        branch=`echo $b | awk '{printf tolower($0)}'`
        if [ "$deployment" == "$branch" ] ; then
            echo "Found deployment $deployment on branch $branch"
            FOUND='y'
        fi
    done

    if [ "$FOUND" == "n" ] ; then
        echo "Deployment $deployment not found on any branch, deleting..."
        helm3 delete --namespace search-jean $d
    fi

done
exit 0
