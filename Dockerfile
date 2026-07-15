# Build các dependences 
FROM node:18-alpine AS deps
WORKDIR /app
COPY src/package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
# Build ứng dụng
FROM node:18-alpine
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY src/ ./
USER node
EXPOSE 3000
CMD ["node", "index.js"]
