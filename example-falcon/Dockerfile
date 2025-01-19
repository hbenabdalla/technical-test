# Build stage
FROM golang:1.20 AS builder

# Set the working directory inside the container
WORKDIR /app

# Set CGO_ENABLED=0 to produce a statically linked binary
ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64

# Copy the Go module files and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the entire application source code
COPY . .

# Build the Go application
RUN go build -o falcon

# Runtime stage
FROM debian:bullseye-slim

# Set the working directory for the runtime container
WORKDIR /app

# Copy the built Go application from the builder stage
COPY --from=builder /app/falcon /app/falcon

# Expose the port that the application listens on
EXPOSE 4000

# Start the application
CMD ["./falcon"]
