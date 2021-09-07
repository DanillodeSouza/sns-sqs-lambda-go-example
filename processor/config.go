package processor

import (
	"log"

	"github.com/kelseyhightower/envconfig"
	"go.uber.org/zap/zapcore"
)

// Config ...
type Config struct {
	APP                    string         `envconfig:"APP_NAME" default:"lambda-example"`
	AWSRegion              string         `envconfig:"AWS_REGION" default:"us-east-1"`
	SQSDestinationEndpoint string         `envconfig:"SQS_DESTINATION_ENDPOINT" default:"http://192.168.15.8:4576/queue/queue-destination-example"`
	LogLevel               LogLevelConfig `envconfig:"LOG_LEVEL" default:"debug"`
}

// NewConfig config constructor
func NewConfig() *Config {
	cfg := &Config{}
	if err := envconfig.Process("", cfg); err != nil {
		log.Fatal(err)
	}

	return cfg
}

// LogLevelConfig log level config.
type LogLevelConfig struct {
	Value zapcore.Level
}
