FROM node:0.10

MAINTAINER Amo Wu <amo260@gmail.com>

WORKDIR /hello-ci-workflow

ADD . /hello-ci-workflow
RUN npm install

EXPOSE 3000
CMD npm start
