FROM golang:alpine AS builder
LABEL authors="vlad.petrovskyi"
WORKDIR /go/src/app

RUN go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest

COPY go.mod .
COPY go.sum .
RUN go mod download

COPY ./ ./

RUN sqlc generate

RUN CGO_ENABLED=0 GOOS=linux go build -o ./run/api ./cmd/api/main.go  \
    && go build -o ./run/migration ./cmd/db/main.go

FROM golang:alpine AS package

WORKDIR /root/

COPY --from=builder /go/src/app/run/ ./
COPY ./config/model.conf ./config/model.conf
COPY ./serviceAccountKey.json ./serviceAccountKey.json
COPY ./db/migrations/ ./db/migrations/
COPY ./db/seeds/ ./db/seeds/

ENV IS_DOCKER_CONTAINER="true"

CMD ["./api"]
