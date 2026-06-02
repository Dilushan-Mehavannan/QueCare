# ===================================================
# STAGE 1: Builder
# ===================================================
FROM node:20-alpine AS builder

# Install build tools for native npm modules
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install all dependencies (including devDependencies) for the build
RUN npm ci

# Copy application source
COPY . .

# Build the production NestJS application
RUN npm run build

# Remove development dependencies to keep production image light
RUN npm prune --production

# ===================================================
# STAGE 2: Production Runner
# ===================================================
FROM node:20-alpine AS runner

WORKDIR /app

# Set production environment flags
ENV NODE_ENV=production

# Copy only the compiled code and production dependencies from builder stage
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

# Expose backend application port
EXPOSE 3000

# Run the compiled NestJS main entrypoint
CMD ["node", "dist/main.js"]
