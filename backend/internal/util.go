package internal

import (
	"os"
	"runtime"
)

func GetEnvVar(varName string, defaultVal string) string {
	env, b := os.LookupEnv(varName)

	if b {
		return env
	} else {
		return defaultVal
	}
}

func GetDefaultHost() string {
	if (runtime.GOOS == "darwin" || runtime.GOOS == "linux") && GetEnvVar("IS_DOCKER_CONTAINER", "false") == "true" {
		return "docker.for.mac.localhost"
	}
	return "localhost"
}
