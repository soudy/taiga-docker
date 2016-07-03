FROM benhutchins/taiga
MAINTAINER Steven Oud <soud@protonmail.com>

COPY taiga-back /usr/src/taiga-back
COPY taiga-front-dist /usr/src/taiga-front-dist

# pip complains about unsupported locale setting when using the default
ENV LC_ALL=C

RUN pip install --no-cache-dir taiga-contrib-slack

ADD https://github.com/taigaio/taiga-contrib-slack/raw/master/front/dist/slack.js /usr/src/taiga-front-dist/dist/slack.js

COPY config/local.py /taiga/local.py
COPY config/conf.json /taiga/conf.json
