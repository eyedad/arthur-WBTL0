# FROM golang:1.23.3-alpine AS builder
#
# WORKDIR /usr/local/src
#
# RUN apk --no-cache add bash git make gcc gettext musl-dev
#
#
# COPY ["go.mod","go.sum","./"]
# COPY cmd/ cmd/
# COPY internal/ internal/
# COPY pkg/ pkg/
# COPY config.yml ./
#
# RUN go mod download
# # ENV CGO_ENABLED=0
# # COPY ["cmd", "internal", "pkg", "config.yml", "./"]
# RUN go build -o ./bin/consumer ./cmd/kafka-consumer/main.go

#==============================================================

FROM golang:1.23.3-bullseye AS builder

WORKDIR /usr/local/src

RUN apt-get update && apt-get install -y \
	git \
	make \
	gcc \
	&& rm -rf /var/lib/apt/lists/*

COPY go.mod go.sum ./
RUN go mod download

COPY cmd/ cmd/
COPY internal/ internal/
COPY pkg/ pkg/
COPY config.yaml ./

RUN go build -o ./bin/consumer cmd/kafka-consumer/main.go
RUN go build -o ./bin/app cmd/main/main.go

FROM golang:1.23.3-bullseye AS consumer_runner

WORKDIR /usr/local/src

COPY --from=builder /usr/local/src/bin/consumer ./
COPY --from=builder /usr/local/src/bin/app ./
COPY config.yaml ./

RUN chmod +x /usr/local/src/consumer
RUN chmod +x /usr/local/src/app

# EXPOSE 8080

CMD ["sh", "-c", "if [ \"$SERVICE\" = 'server' ]; then /usr/local/src/app; else /usr/local/src/consumer; fi"]

#:=:======================================================

# FROM postgres:latest
# ADD ./migrations/initdb.sql /docker-entrypoint-initdb.d/

