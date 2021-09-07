awslocal lambda update-function-code \
    --dry-run \
    --function-name lambda-example \
    --zip-file fileb://bin/linux_amd64/lambda-example.zip
