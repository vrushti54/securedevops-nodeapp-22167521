FROM node:16-alpine

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm ci --omit=dev

COPY app.js ./

EXPOSE 8080

CMD ["npm", "start"]
