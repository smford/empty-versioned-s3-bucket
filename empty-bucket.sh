#!/usr/bin/env bash

BUCKET="my-bucket-name"
BUCKET_PREFIX="a-directory-within-the-bucket"

# 1000 is the maximum that the s3api allows
STEPSIZE=1000

DATE=$(date +%F_%H%M)
MYDIR="$BUCKET/$BUCKET_PREFIX"

mkdir -p $MYDIR

DETAILS=`aws s3 ls --summarize --human-readable --recursive s3://$BUCKET/$BUCKET_PREFIX`
echo $DETAILS > $MYDIR/$DATE-details.txt

ALL=`aws s3api list-object-versions --bucket "$BUCKET" --prefix "$BUCKET_PREFIX" --query "[Versions,DeleteMarkers][].{Key: Key, VersionId: VersionId}"`
echo $ALL > $MYDIR/$DATE-all.txt
ALL_COUNT=`echo $ALL | jq 'length'`

VERSIONS=`aws s3api list-object-versions --bucket "$BUCKET" --prefix "$BUCKET_PREFIX" --query "[Versions][].{Key: Key, VersionId: VersionId}"`
echo $VERSIONS > $MYDIR/$DATE-versions.txt
VERSIONS_COUNT=`echo $VERSIONS | jq 'length'`

DELETEMARKERS=`aws s3api list-object-versions --bucket "$BUCKET" --prefix "$BUCKET_PREFIX" --query "[DeleteMarkers][].{Key: Key, VersionId: VersionId}"`
echo $DELETEMARKERS > $MYDIR/$DATE-deletemarkers.txt
DELETEMARKERS_COUNT=`echo $DELETEMARKERS | jq 'length'`

echo "       Bucket: s3://$BUCKET/$BUCKET_PREFIX"
echo "          All: $ALL_COUNT"
echo "     Versions: $VERSIONS_COUNT"
echo "DeleteMarkers: $DELETEMARKERS_COUNT"
echo "   Date Stamp: $DATE"
echo "    Step Size: $STEPSIZE"
echo "         Logs: $MYDIR/$DATE-*"

echo ""
read -p "Press [Enter] to contine or Ctrl-C to cancel"

if [ $ALL_COUNT -le 0 ]; then
  echo "No versioned objects or delete markers found, exiting"
  exit 1
fi

echo "Removing files"
i=0
while [ $i -lt $VERSIONS_COUNT ]
do
  next=$((i+$STEPSIZE-1))
  if [ $next -ge $VERSIONS_COUNT ]; then
    next=$VERSIONS_COUNT
  fi
  toprocess=$(cat "$MYDIR/$DATE-versions.txt" | jq '.[] | {Key,VersionId}' | jq -s '.' | jq .[$i:$next])
  cat << EOF > $MYDIR/$DATE-versions-$BUCKET_PREFIX-$i-$next.json
{"Objects":$toprocess, "Quiet":true}
EOF
  echo "Removing files from $i - $next"
  aws s3api delete-objects --bucket "$BUCKET" --delete file://$MYDIR/$DATE-versions-$BUCKET_PREFIX-$i-$next.json >> $MYDIR/$DATE-$BUCKET_PREFIX.log
  let i=i+$STEPSIZE
done

echo "Removing DeleteMarkers"
i=0
while [ $i -lt $DELETEMARKERS_COUNT ]
do
  next=$((i+$STEPSIZE-1))
  if [ $next -ge $DELETEMARKERS_COUNT ]; then
    next=$DELETEMARKERS_COUNT
  fi
  toprocess=$(cat "$MYDIR/$DATE-deletemarkers.txt" | jq '.[] | {Key,VersionId}' | jq -s '.' | jq .[$i:$next])
  cat << EOF > $MYDIR/$DATE-deletemarkers-$BUCKET_PREFIX-$i-$next.json
{"Objects":$toprocess, "Quiet":true}
EOF
  echo "Removing DeleteMarkers from $i - $next"
  aws s3api delete-objects --bucket "$BUCKET" --delete file://$MYDIR/$DATE-deletemarkers-$BUCKET_PREFIX-$i-$next.json >> $MYDIR/$DATE-$BUCKET_PREFIX.log
  let i=i+$STEPSIZE
done
