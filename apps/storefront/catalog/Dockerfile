FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production --audit-level=high
COPY . .
EXPOSE 8080
USER node
CMD ["node", "index.js"]
