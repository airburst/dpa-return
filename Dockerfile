FROM gliderlabs/alpine:3.5

# Install OS dependencies
# sudo apk add --update <package>

# Create app directory
RUN mkdir -p /usr/app
WORKDIR /usr/app

# Install app dependencies
COPY package.json /usr/app/
RUN npm install

# Bundle app source
COPY . /usr/app

# Make logfiles available outside container
VOLUME  ["/usr/app/logs"]

EXPOSE 4000
CMD [ "npm", "start" ]
