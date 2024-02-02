FROM golang:alpine AS builder
LABEL authors="vlad.petrovskyi"
WORKDIR /go/src/app

RUN go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest

COPY go.mod .
COPY go.sum .
RUN go mod download

COPY ./ ./

RUN sqlc generate

RUN CGO_ENABLED=0 GOOS=linux go build -o ./run .

FROM golang:alpine

WORKDIR /root/

COPY --from=builder /go/src/app/run/ ./
COPY ./config/model.conf ./config/model.conf
COPY ./serviceAccountKey.json ./serviceAccountKey.json

EXPOSE 8080

CMD ["./run"]
