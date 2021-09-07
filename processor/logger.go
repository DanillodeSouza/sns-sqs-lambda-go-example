package processor

import (
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// NewLogger returns an usable zap logger.
func NewLogger(logLevel LogLevelConfig) (*zap.Logger, error) {
	logger, err := configLog(zap.NewAtomicLevelAt(logLevel.Value)).Build()
	if err != nil {
		return nil, err
	}

	return logger, nil
}

// LogError logs an error to stderr including some internal information
func LogError(logger *zap.Logger, msg string) {
	logger.Error(msg)
}

// LogInfo logs a info to stdout when info Log Level is active
func LogInfo(logger *zap.Logger, msg string) {
	logger.Info(msg)
}

func configLog(level zap.AtomicLevel) zap.Config {
	return zap.Config{
		Level:         level,
		Development:   false,
		DisableCaller: true,
		Sampling:      nil,
		Encoding:      "json",
		EncoderConfig: zapcore.EncoderConfig{
			TimeKey:        "time",
			LevelKey:       "level",
			NameKey:        "logger",
			CallerKey:      "caller",
			MessageKey:     "msg",
			LineEnding:     zapcore.DefaultLineEnding,
			EncodeLevel:    zapcore.LowercaseLevelEncoder,
			EncodeTime:     zapcore.ISO8601TimeEncoder,
			EncodeDuration: millisDurationEncoder,
			EncodeCaller:   zapcore.ShortCallerEncoder,
		},
		OutputPaths:      []string{"stdout"},
		ErrorOutputPaths: []string{"stderr"},
	}
}

func millisDurationEncoder(d time.Duration, enc zapcore.PrimitiveArrayEncoder) {
	enc.AppendInt(int(float64(d) / float64(time.Millisecond)))
}
