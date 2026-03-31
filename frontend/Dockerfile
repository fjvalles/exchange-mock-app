FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
COPY . .

EXPOSE 5173

# Install deps at startup (leverages node_modules volume cache on restarts)
CMD sh -c "npm install --prefer-offline 2>/dev/null || npm install && npm run dev -- --host 0.0.0.0"
