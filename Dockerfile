FROM node:22.11.0-slim AS builder

WORKDIR /usr/src/app

COPY --chown=node:node package.json ./
COPY --chown=node:node package-lock.json ./

RUN npm install

COPY --chown=node:node . .

RUN npm run build

USER node

FROM node:22.11.0-slim AS production

COPY --chown=node:node --from=builder /usr/src/app/node_modules ./node_modules
COPY --chown=node:node --from=builder /usr/src/app/dist ./dist
COPY --chown=node:node package.json ./
COPY --chown=node:node tsconfig.json ./


CMD ["npm", "start"]