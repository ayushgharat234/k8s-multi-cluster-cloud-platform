# Build Stage
FROM golang:1.22-alpine AS builder
WORKDIR /app

# Download dependencies first (caching)
COPY go.mod ./
# COPY go.sum ./
RUN go mod download

# Build the application
COPY . .
# CGO_ENABLED=0 is required for Distroless (static binary)
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# Final Stage (Distroless - Secure & Minimal)
# Use 'static' for Go apps (no libc needed)
FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /app/main .
USER 65532:65532

EXPOSE 8080
ENTRYPOINT ["/main"]
