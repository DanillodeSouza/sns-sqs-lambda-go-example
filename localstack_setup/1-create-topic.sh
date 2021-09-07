TOPIC_NAME=sns-topic-example

echo "Creating topic $TOPIC_NAME"

CREATE_OUTPUT=$(awslocal sns create-topic \
    --name "$TOPIC_NAME")

if [ $? -eq 0 ]
then
    printf "Topic %s created.\n%s\n" "$TOPIC_NAME" "$CREATE_OUTPUT"
else
    echo "Some error ocurred when creating $TOPIC_NAME: $CREATE_OUTPUT"
fi

echo "Sns initialization completed"
