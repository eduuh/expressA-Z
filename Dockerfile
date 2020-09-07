FROM node:14-slim as base
LABEL org.opencontainers.image.authors=edwin@muraya
LABEL org.opencontainers.image.title="Azure Container Registry"
LABEL org.opencontainers.image.licenses=MIT
LABEL com.edwin.nodeversion=$NODE_VERSION

ENV NODE_ENV=production
EXPOSE 8080
ENV PORT 8080
WORKDIR /app
COPY package*.json ./
RUN npm config list
RUN npm ci && npm cache clean --force

ENV PATH /app/node_modules/.bin:$PATH
CMD [ "node", "./bin/www"" ]

FROM base as dev
ENV NODE_ENV=development
RUN apt-get update -qq && apt-get install -qy \ 
    ca-certificates \
    bzip2 \
    curl \
    libfontconfig \
    --no-install-recommends
RUN npm config list
RUN  npm install --only=development && npm cache clean --force
USER node
CMD [ "nodemon", "./bin/www" ]

FROM dev as test
COPY . .
RUN npm audit 

From dev as seeder
CMD node seeder -d && node seeder -i

FROM test as pre-prod
USER root
RUN rm -rf ./tests && rm -rf ./node_modules

FROM base as prod
COPY --from=pre-prod /app /app
HEALTHCHECK CMD curl http://127.0.0.1/ || exit 1
USER node

