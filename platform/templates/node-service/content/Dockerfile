# Build Stage
# Use a full Node.js image to build dependencies
FROM node:20-bookworm AS builder
WORKDIR /app

# Copy package files first to leverage Docker cache for dependencies
COPY package*.json ./

# Install only production dependencies for a smaller final image
# 'npm ci' ensures a deterministic install based on package-lock.json
RUN npm ci --only=production

# Final Stage (Distroless)
# Use a distroless image for better security (no shell, smaller size)
# See: https://github.com/GoogleContainerTools/distroless
FROM gcr.io/distroless/nodejs20-debian12
WORKDIR /app

# Copy installed node_modules from the builder stage
COPY --from=builder /app/node_modules ./node_modules

# Copy application source code
COPY . .

# Run as non-root user for security (65532 is the nonroot user in distroless)
USER 65532

EXPOSE 3000
CMD ["index.js"]