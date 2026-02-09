# Build Stage
FROM dhi.io/golang:1-debian13-sfw-ent-dev AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server

# Runtime Stage
FROM dhi.io/golang:1-debian13-sfw-ent-dev
WORKDIR /app
COPY --from=builder /app/server .
# Security: Run as non-root user
USER 1001
EXPOSE 8080
CMD ["./server"]