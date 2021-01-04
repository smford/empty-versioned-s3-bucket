# empty-versioned-s3-bucket

A simple script that will empty a directory within a bucket, nuking all versions of a file and all delete markers.

It works, it is not elegant, does no error checking, and only does rudimentary logging.

Dumps output into a new directory ./bucket-name/bucket-prefix/datestamp-*

## Usage

1. Edit these two lines: https://github.com/smford/empty-versioned-s3-bucket/blob/main/empty-bucket.sh#L3-L4
1. Change `BUCKET="my-bucket-name"` to your bucket name
1. Change `BUCKET_PREFIX="a-directory-within-the-bucket"` to the prefix (or directory name) which contains the items you wish to delete

## Notes

- It can take a few moments from AWS to process the delete request and action it
- You may need to run the script a couple times as occassionally AWS appears not to actually do a delete upon first request

## Credits and Inspiration

- https://gist.github.com/weavenet/f40b09847ac17dd99d16
- https://gist.github.com/wknapik/191619bfa650b8572115cd07197f3baf
- https://gist.github.com/nashjain/6119aecd5e8919d0818773a118d05ed6
