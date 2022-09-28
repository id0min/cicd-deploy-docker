FROM ubuntu:xenial

###
# Install dependencies
#

RUN apt-get update && \
    apt-get install -qq -y --no-install-recommends \
      apt-transport-https \
      build-essential \
      ca-certificates \
      curl \
      git-core \
      python-software-properties && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get -y autoclean

###
# Install Node.js
#

# gpg keys listed at https://github.com/nodejs/node
RUN set -ex \
  && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
  ; do \
    for server in $( \
      shuf -e ha.pool.sks-keyservers.net \
      hkp://p80.pool.sks-keyservers.net:80 \
      keyserver.ubuntu.com \
      hkp://keyserver.ubuntu.com:80 \
      keyserver.pgp.com \
      pgp.mit.edu \
    ) ; do \
      gpg --keyserver "$server" --recv-keys "$key" && break || : ; \
    done; \
  done

ENV NODE_VERSION 7.9.0

RUN set -x \
    && rm -rf /var/lib/apt/lists/* \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
    && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt

###
# Set up the working directory
#

ENV APP_DIR /app

RUN mkdir -p "${APP_DIR}"
WORKDIR "${APP_DIR}"

###
# Install PM2 for process management
#

ENV PM2_VERSION 2.4.5

RUN npm install -g pm2@$PM2_VERSION

###
# Install Yarn for faster and reliable Node.js module management
#

ENV YARN_VERSION 0.22.0

RUN npm install -g yarn@$YARN_VERSION

###
# Install Node.js module dependencies
#

COPY package.json .
COPY yarn.lock .
RUN yarn

###
# Let's get started!
#

COPY . .

ENV PORT 8000

EXPOSE "${PORT}"

CMD ["pm2-docker", "start", "ecosystem.config.js"]
