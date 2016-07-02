# Taiga Docker container
This repository holds an image ready-to-use setup for Taiga using Docker
compose. You can launch an instance by simply running `docker-compose up`.

Copy-paste instructions for the lazy:
```sh
git clone git@github.com:soudy/taiga-docker.git --recursive
cd taiga-docker
docker-compose up # or build, whatever you want
```

## Configuration
Application configuration can be done in `taiga-conf/local.py` and
`taiga-conf/conf.json`. The most important thing is setting your hostname both
in `docker-compose.yml` and `taiga-conf/conf.json`, otherwise the front-end
won't be able to talk with the back-end.
