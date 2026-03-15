FROM node:20-alpine

ARG SERVICE_PATH
WORKDIR /app

COPY package.json package-lock.json* ./
COPY backend ./backend
COPY admin-web ./admin-web

RUN npm install
WORKDIR /app/${SERVICE_PATH}
CMD ["npm", "run", "dev"]

