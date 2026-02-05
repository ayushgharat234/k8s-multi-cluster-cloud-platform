# Build Stage
FROM dhi.io/node:25-debian13-sfw-ent-dev AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Runtime Stage
FROM dhi.io/node:25-debian13-sfw-ent-dev
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY . .
USER 1001
EXPOSE 8080
CMD ["node", "index.js"]