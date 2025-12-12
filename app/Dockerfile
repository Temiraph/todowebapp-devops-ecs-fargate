# ------------ Build stage ------------
FROM node:18-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install --only=production

COPY . .

# ------------ Runtime stage ------------
FROM node:18-alpine

WORKDIR /usr/src/app

# Copy node_modules and app code from builder
COPY --from=builder /usr/src/app /usr/src/app

# The app listens on 3000 (based on your Nginx/Node setup)
EXPOSE 3000

# Environment variables will be injected at runtime by ECS
CMD ["node", "index.js"]

