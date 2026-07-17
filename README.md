# x_analyzer

> Shell-driven deployment automation for a distributed Kafka + Spark streaming data pipeline on AWS EC2.

## Overview

`x_analyzer` is a collection of Bash deployment scripts that stand up a real-time
streaming data pipeline across multiple AWS EC2 instances. Each stage of the
pipeline runs on its own instance and is provisioned remotely over SSH:

1. **ZooKeeper** — coordination service for the Kafka cluster.
2. **Kafka broker + producer** — a Kafka broker that connects to the external
   ZooKeeper, plus a Python producer that publishes messages to a topic.
3. **Spark consumer** — an Apache Spark Streaming job that consumes messages from
   Kafka and runs a streaming word-count over them.

The shell scripts are the core of the project: they copy the required files to
each instance with `scp`, then connect with `ssh` to install dependencies
(Docker, Spark, Kafka, Python) and launch the corresponding service.

> **Note on the name:** despite the `x_analyzer` name, the code in this
> repository does not integrate with X/Twitter. `tweepy` is listed in
> `requirements.txt`, but the producer that ships here simply emits sample JSON
> messages (`{'number': i}`) to demonstrate the end-to-end pipeline. The
> intended flow is: producer → Kafka → Spark Streaming.

A deprecated Apache Flink-based consumer (an alternative to the Spark consumer)
is kept for reference under the `garbage/` directory.

## Architecture

```
+------------------+      +---------------------------+      +-------------------+
|  ZooKeeper EC2   |<-----|  Kafka Broker EC2         |      |  Spark EC2        |
|  zookeeper:3.6.3 |      |  bitnami/kafka            |      |  Spark Streaming  |
|  port 2181       |      |  port 9092                |      |  word count       |
+------------------+      |  + kafka_producer.py      |----->|  consumer         |
                          +---------------------------+      +-------------------+
```

- The producer publishes JSON messages to the Kafka topic.
- The Spark consumer reads the stream, splits messages into words, and prints a
  running word count every 10 seconds.

## Requirements

### Local machine (from where you run the deploy scripts)

- A Unix-like shell (`bash`)
- `ssh` and `scp` (OpenSSH)
- An AWS EC2 key pair (`.pem` file)
- Running AWS EC2 instances for ZooKeeper, the Kafka broker, and the Spark
  consumer, reachable over SSH as the `ubuntu` user

### Provisioned automatically on the EC2 instances

The `init_*.sh` scripts install these on the target instances:

- Docker (`docker.io`)
- Python 3 and `pip`
- Apache Spark 3.3.1 (with Hadoop 3) and Apache Kafka 2.13-2.8.0 (Spark instance)
- Docker images: `zookeeper:3.6.3`, `bitnami/kafka:latest`, and a locally built
  `kafka-producer` image
- Python packages: `kafka-python`, `python-dotenv` (see `requirements.txt`)

## Configuration

Two configuration files drive the deployment.

### `.env` (used by the deploy scripts on your local machine)

Defines the SSH key path and the target instance addresses. Expected keys:

| Variable | Description |
| --- | --- |
| `PEM_PATH` | Path to your EC2 `.pem` private key |
| `EC2_PUBLIC_DNS_ZOOKEEPER` | Public DNS/IP of the ZooKeeper instance |
| `EC2_PUBLIC_DNS_PRODUCER_BROKER` | Public DNS/IP of the Kafka broker/producer instance |
| `EC2_PUBLIC_DNS_SPARK_CONSUMER` | Public DNS/IP of the Spark consumer instance |
| `EC2_PUBLIC_DNS_FLINK_CONSUMER` | Public DNS/IP of the (deprecated) Flink instance |
| `PRIVATE_ZOOKEEPER_IP` | Private IP of the ZooKeeper instance |
| `S3_BUCKET` | Target S3 bucket |
| `KAFKA_PRODUCER_SCRIPT` | Producer script filename |
| `FLINK_CONSUMER_SCRIPT` | Flink consumer script filename |

### `config.env` (copied to the Kafka broker instance)

Holds Kafka/ZooKeeper wiring used inside the broker instance, e.g.
`KAFKA_VERSION`, `ZOOKEEPER_IP`, `KAFKA_BROKER_IP`, `KAFKA_PRODUCER_SCRIPT`,
and `S3_BUCKET`.

> **Security warning:** commit real credentials, private IPs, and key material
> with care. The values shipped in this repository are examples — replace them
> with your own and avoid committing secrets or `.pem` files (`.pem` is already
> covered by `.gitignore`).

## Installation

Clone the repository:

```bash
git clone https://github.com/AckerCoder/x_analyzer.git
cd x_analyzer
```

Create/edit your `.env` and `config.env` with the values for your AWS
environment, and make sure your `.pem` key is available at `PEM_PATH`.

## Usage

Deploy the services in order. Each script uploads the required files to the
matching EC2 instance and runs its initialization script remotely.

### 1. Deploy ZooKeeper

```bash
./deploy_zookeeper.sh
```

Uploads and runs `init_zookeeper.sh`, which installs Docker and starts a
`zookeeper:3.6.3` container on port 2181.

### 2. Deploy the Kafka broker and producer

```bash
./deploy_kafka_producer_broker.sh
```

Uploads `init_kafka_producer_broker.sh`, `Dockerfile.kafka-producer`, the
producer script, and `config.env`. On the instance it installs Docker, creates a
`kafka-network`, starts a `bitnami/kafka` broker (connected to the external
ZooKeeper), builds the `kafka-producer` image, and runs the producer.

### 3. Deploy the Spark consumer

```bash
./deploy_spark_consumer.sh
```

Uploads `docker-compose-spark.yml`, `spark_kafka_consumer.py`,
`Dockerfile.spark-consumer`, and `init_spark_consumer.sh`. On the instance,
`init_spark_consumer.sh` installs Java, Scala, Spark 3.3.1, and Kafka; downloads
the Spark–Kafka streaming JARs; and submits the consumer job with `spark-submit`.

Access an EC2 instance directly with SSH if you need to inspect it:

```bash
ssh -i /path/to/your-key.pem ubuntu@<instance-public-dns>
```

## How it works

### Producer — `scripts/kafka_producer.py`

Creates a `KafkaProducer` (bootstrap server `kafka:9092`) that serializes values
as JSON, then sends 100 messages of the form `{'number': i}` to the `my_topic`
topic and closes the connection.

### Spark consumer — `scripts/spark_kafka_consumer.py`

Builds a Spark `StreamingContext` with a 10-second batch interval, opens a direct
Kafka DStream on the configured topic, splits each incoming message into words,
and prints a running word count with `pprint()`.

### Docker & Compose

- `Dockerfile.kafka-producer` — Python 3.9 image that installs `kafka-python`
  and `python-dotenv` and runs the producer.
- `Dockerfile.spark-consumer` — `bitnami/spark:3.3.1` image that pulls the
  Spark–Kafka streaming JARs and runs the consumer via `spark-submit`.
- `docker-compose-spark.yml` — waits for the Kafka broker to be reachable on
  port 9092, then launches the Spark consumer.

## Repository layout

```
.
├── deploy_zookeeper.sh              # Deploy ZooKeeper to its EC2 instance
├── deploy_kafka_producer_broker.sh  # Deploy Kafka broker + producer
├── deploy_spark_consumer.sh         # Deploy the Spark Streaming consumer
├── init_zookeeper.sh                # Remote provisioning: ZooKeeper
├── init_kafka_producer_broker.sh    # Remote provisioning: Kafka broker/producer
├── init_spark_consumer.sh           # Remote provisioning: Spark consumer
├── Dockerfile.kafka-producer        # Producer image
├── Dockerfile.spark-consumer        # Spark consumer image
├── docker-compose-spark.yml         # Compose file for the Spark consumer
├── config.env                       # Kafka/ZooKeeper config (broker instance)
├── requirements.txt                 # Python dependencies
├── scripts/
│   ├── kafka_producer.py            # Kafka producer (sample JSON messages)
│   └── spark_kafka_consumer.py      # Spark Streaming word-count consumer
└── garbage/                         # Deprecated Flink-based consumer variant
```

## Notes

Several scripts and comments in this repository are written in Spanish. The
deployment targets Ubuntu-based EC2 instances and assumes the `ubuntu` SSH user.

## License

No license file is currently included in this repository.
