#!/usr/bin/env bash

set -e
set -x

#BUCKET=$1
#BUCKET_PREFIX=$2

BUCKET="mybucket"
BUCKET_PREFIX="somedirectory"

STEPSIZE=49

mkdir -p $BUCKET/$BUCKET_PREFIX

DETAILS=`aws s3 ls --summarize --human-readable --recursive s3://$BUCKET/$BUCKET_PREFIX`
echo $DETAILS > $BUCKET/$BUCKET_PREFIX/details.txt

ALL=`aws s3api list-object-versions --bucket "$BUCKET" --prefix "$BUCKET_PREFIX" --query "[Versions,DeleteMarkers][].{Key: Key, VersionId: VersionId}"`
echo $ALL > $BUCKET/$BUCKET_PREFIX/all.txt
ALL_COUNT=`echo $ALL | jq 'length'`

VERSIONS=`aws s3api list-object-versions --bucket "$BUCKET" --prefix "$BUCKET_PREFIX" --query "[Versions][].{Key: Key, VersionId: VersionId}"`
echo $VERSIONS > $BUCKET/$BUCKET_PREFIX/versions.txt
VERSIONS_COUNT=`echo $VERSIONS | jq 'length'`

DELETEMARKERS=`aws s3api list-object-versions --bucket "$BUCKET" --prefix "$BUCKET_PREFIX" --query "[DeleteMarkers][].{Key: Key, VersionId: VersionId}"`
echo $DELETEMARKERS > $BUCKET/$BUCKET_PREFIX/deletemarkers.txt
DELETEMARKERS_COUNT=`echo $DELETEMARKERS | jq 'length'`

echo "          All: $ALL_COUNT"
echo "     Versions: $VERSIONS_COUNT"
echo "DeleteMarkers: $DELETEMARKERS_COUNT"

#ALL_COUNT=`cat all_zero.txt | jq 'length'`
if [ $ALL_COUNT -le 0 ]; then
  echo "No versioned objects or delete markers found exiting"
  exit 1
fi

i=0
while [ $i -lt $VERSIONS_COUNT ]
do
  next=$((i+$STEPSIZE-1))
  if [ $next -ge $VERSIONS_COUNT ]; then
    next=$VERSIONS_COUNT
  fi
  toprocess=$(cat "$BUCKET/$BUCKET_PREFIX/versions.txt" | jq '.[] | {Key,VersionId}' | jq -s '.' | jq .[$i:$next])
  cat << EOF > $BUCKET/$BUCKET_PREFIX/versions-$BUCKET_PREFIX-$i-$next.json
{"Objects":$toprocess, "Quiet":true}
EOF
  echo "Deleting records from $i - $next"
  aws s3api delete-objects --bucket "$BUCKET" --delete file://$BUCKET/versions-$BUCKET_PREFIX-$i-$next.json >> $BUCKET/$BUCKET_PREFIX/$BUCKET_PREFIX.log
  let i=i+$STEPSIZE
done
