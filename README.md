# NF_handling_v_podman-compose

- dependencies
  - podman
  - podman-compose
  - connected 8.8.8.8

- Usage
  - ./core.sh -net xxx.xxx.xxx -name yyyy 
    -net        : Network range to create container network boundary.
                : xxx.xxx.xxx(String='Number+dot')   
    -name       : Slave NIC Network name.
                : yyyy(String, ex. ens8) 

  - ./core.sh -rm
    -rm         : Stop all containers and Remove network.

  - ./core.sh -h or --help
    -h or --help  : usage
