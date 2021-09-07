# SNS SQS Lambda Go Example
---

## Pre-requisites

`docker version 17+` See how to download and install in [Docker site.](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

`docker-compose version 1.20+` See how to download and install in [Docker site.](https://docs.docker.com/compose/install/#install-compose)

`golang version 1.11+`  See how to download and install in [Golang site.](https://golang.org/doc/install)


### Makefile
---

Some commands on this project are made using `GNU make`, to know available actions on make, use `make` or `make usage`:

```bash
make

make usage
```

---
## Development
Copy env vars:
```bash
cp .env.example .env
```


Build the lambda (Generate GO binary, run golint and run unit tests):
```bash
make build
```

Start docker-compose services:
```bash
make start
```

Stop and remove docker-compose services:
```bash
make stop
```

Run the dependencies:
```bash
docker-compose up
```

```
awslocal sns publish --topic-arn arn:aws:sns:us-east-1:000000000000:sns-topic-example --message "{\"match\":{\"id\": 1}}"
```
