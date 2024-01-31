- dependencies
  - podman
  - podman-compose
 
- environment
  - any vm or physical server
  - any linux that cent or deb
  - connected 8.8.8.8

- usage
  - ./core.sh -net xxx.xxx.xxx -name yyyy\
    -net        : Network range to create container network boundary. (xxx.xxx.xxx (String='Number+dot', ex.172.126.0))\
    -name       : Slave NIC Network name. (yyyy (String, ex. ens8))

  - ./core.sh -rm\
    -rm         : Stop all containers and Remove network.

  - ./core.sh -h or --help\
    -h or --help  : usage

24.01.31 추가 수정 중

