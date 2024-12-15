FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o api .

# Final stage
FROM alpine:latest

WORKDIR /root/

# Copy the pre-built binary
COPY --from=builder /app/api .

# Expose port
EXPOSE 8080

# Command to run the executable
CMD ["./api"]