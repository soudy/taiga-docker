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

## Swarm
For deployment, I decided to try the new Docker swarm out (the native one).
I will now describe how to set up a Docker swarm for taiga.

### Set up a key-value store
1. First thing we need to do is setup our key-value store. Create a machine
    named `keystore`.
    ```bash
    $ docker-machine create -d virtualbox keystore
    ```

2. Set your local environment to the keystore machine.
    ```bash
    $ eval "$(docker-machine env keystore)"
    ```

3. Start a progrium/consul container running on the keystore machine.
    ```bash
    $ docker run -d \
        -p "8500:8500" \
        -h "consul" \
        progrium/consul -server -bootstrap
    ```
4. Verify it's running by checking `docker ps`
    ```bash
    $ docker ps
    CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                                                            NAMES
    32c13b3a0ece        progrium/consul     "/bin/start -server -"   27 seconds ago      Up 27 seconds       53/tcp, 53/udp, 8300-8302/tcp, 8400/tcp, 8301-8302/udp, 0.0.0.0:8500->8500/tcp   distracted_payne
    ```

### Create a Swarm cluster
1. Create a swarm master.
    ```bash
    $ docker-machine create \
        -d virtualbox \
        --swarm --swarm-master \
        --swarm-discovery="consul://$(docker-machine ip keystore):8500" \
        --engine-opt="cluster-store=consul://$(docker-machine ip keystore):8500" \
        --engine-opt="cluster-advertise=eth1:2376" \
        manager
    ```
2. Create as many additional hosts as you want. I went with 2.
    ```bash
    $ docker-machine create -d virtualbox \
        --swarm \
        --swarm-discovery="consul://$(docker-machine ip keystore):8500" \
        --engine-opt="cluster-store=consul://$(docker-machine ip keystore):8500" \
        --engine-opt="cluster-advertise=eth1:2376" \
        agent1
    ```
3. List your machines to verify they're running.
    ```bash
    $ docker-machine ls
    NAME       ACTIVE   DRIVER       STATE     URL                         SWARM              DOCKER    ERRORS
    agent1     -        virtualbox   Running   tcp://192.168.99.106:2376   manager            v1.11.2
    agent2     -        virtualbox   Running   tcp://192.168.99.107:2376   manager            v1.11.2
    keystore   -        virtualbox   Running   tcp://192.168.99.104:2376                      v1.11.2
    manager    -        virtualbox   Running   tcp://192.168.99.105:2376   manager (master)   v1.11.2
    ```

### Create the overlay Network
1. Set your docker environment to the Swarm master.
    ```bash
    $ eval "$(docker-machine env --swarm manager)"
    ```

2. Use the docker info command to view the Swarm
    ```bash
    Containers: 4
     Running: 4
     Paused: 0
     Stopped: 0
    Images: 3
    Server Version: swarm/1.2.3
    Role: primary
    Strategy: spread
    Filters: health, port, containerslots, dependency, affinity, constraint
    Nodes: 3
     agent1: 192.168.99.106:2376
      └ ID: MUXU:D5SQ:N4GQ:2XWT:E47S:3LZZ:7VZB:V247:XHRT:ECVL:INUU:72P4
      └ Status: Healthy
      └ Containers: 1
      └ Reserved CPUs: 0 / 1
      └ Reserved Memory: 0 B / 1.021 GiB
      └ Labels: executiondriver=, kernelversion=4.4.12-boot2docker, operatingsystem=Boot2Docker 1.11.2 (TCL 7.1); HEAD : a6645c3 - Wed Jun  1 22:59:51 UTC 2016, provider=virtualbox, storagedriver=aufs
      └ UpdatedAt: 2016-07-03T12:23:42Z
      └ ServerVersion: 1.11.2
     agent2: 192.168.99.107:2376
      └ ID: GQEU:54KI:UX6K:73HB:APKA:YUVL:NNAG:XGIB:67VP:7OTR:3FSV:DHYE
      └ Status: Healthy
      └ Containers: 1
      └ Reserved CPUs: 0 / 1
      └ Reserved Memory: 0 B / 1.021 GiB
      └ Labels: executiondriver=, kernelversion=4.4.12-boot2docker, operatingsystem=Boot2Docker 1.11.2 (TCL 7.1); HEAD : a6645c3 - Wed Jun  1 22:59:51 UTC 2016, provider=virtualbox, storagedriver=aufs
      └ UpdatedAt: 2016-07-03T12:23:47Z
      └ ServerVersion: 1.11.2
     manager: 192.168.99.105:2376
      └ ID: MEGK:TMCN:KJFZ:GIP3:RZ7O:NJYG:5QKA:QX4Z:YQSO:HXF2:NWKO:CCVA
      └ Status: Healthy
      └ Containers: 2
      └ Reserved CPUs: 0 / 1
      └ Reserved Memory: 0 B / 1.021 GiB
      └ Labels: executiondriver=, kernelversion=4.4.12-boot2docker, operatingsystem=Boot2Docker 1.11.2 (TCL 7.1); HEAD : a6645c3 - Wed Jun  1 22:59:51 UTC 2016, provider=virtualbox, storagedriver=aufs
      └ UpdatedAt: 2016-07-03T12:23:39Z
      └ ServerVersion: 1.11.2
    Plugins:
     Volume:
     Network:
    Kernel Version: 4.4.12-boot2docker
    Operating System: linux
    Architecture: amd64
    ```
3. Create your overlay network.
    ```bash
    $ docker network create --driver overlay --subnet=10.0.9.0/24 my-net
    ```

4. Check that the network is running
    ```bash
    $ docker network ls
    NETWORK ID          NAME                DRIVER
    f2eab9a20968        agent1/bridge       bridge
    6f77321e84dd        agent1/host         host
    d20b2c07197e        agent1/none         null
    425c321c6712        agent2/bridge       bridge
    a5ba200d88b8        agent2/host         host
    e4f6c3c95eb1        agent2/none         null
    4b57a828503c        manager/bridge      bridge
    c6169c7df609        manager/host        host
    6e637616d970        manager/none        null
    2349f4d38af5        my-net              overlay
    ```
### Running the application
1. Point your environment to the Swarm master.
    ```bash
    $ eval "$(docker-machine env --swarm manager)"
    ```

2. Start the containers.
    ```bash
    $ docker-compose up -d
    ```

3. Scale up as much as you want!
    ```bash
    $ docker-compose scale postgres=4
    ```
