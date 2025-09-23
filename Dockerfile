FROM node:18-alpine

# App directory
WORKDIR /app

# Install deps (use lockfile if present)
COPY package*.json ./
RUN npm ci --omit=dev

# Copy source
COPY . .

# Runtime env
ENV NODE_ENV=production
ENV PORT=8080

# Health & network
EXPOSE 8080

# Start the app (uses "start" script in package.json)
CMD ["npm","start"]
