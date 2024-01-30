#!/bin/bash

usage() {
cat <<EOF

Usage
  - ./core.sh -net xxx.xxx.xxx -name yyyy 
  |
  | -net        : Network range to create container network boundary.
  |             : xxx.xxx.xxx(String='Number+dot')   
  |
  | -name       : Slave NIC Network name.
                : yyyy(String, ex. ens8) 

  - ./core.sh -rm
  |
  | -rm         : Stop all containers and Remove network.

  - ./core.sh -h or --help
  | -h or --help  : usage

EOF
exit
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  msg "$msg"
  exit 
}

sctp_check() {
  ckcurtos=`grep . /etc/*-release | grep ID_LIKE | cut -d '"' -f2`
  sctpox=''
  os=''

  if [[("$ckcurtos" == *centos*)]] || \
     [[("$ckcurtos" == *fedora*)]] || \
     [[("$chcurtos" == *rhel*)]]; then
    echo "centos"; os="centos";
    sctpox=`yum list installed | grep kernel-modules-extra`
  elif [[("$ckcurtos" == *ubuntu*)]] || \
      [[("$ckcurtos" == *debian*)]]; then
    echo "debian"; os="debian";
    sctpox=`apt list --installed | grep libsctp-dev`
  else
    die "Please check OS version.";
  fi
  
  if [ -z "$sctpox" ]; then
    if [ -z "$os" ]; then
      if [$os == "centos"]; then
        yum install -y kernel-modules-extra
        modprobe sctp
      elif [$os == "ubuntu"]; then
        apt update && apt install -y libsctp-dev lksctp-tools
      fi
    fi
  else
    msg "${GREEN}'kernel-modules-extra' is already installed.${NOFORMAT}"
  fi

  return 0
}

make_db_container() {
  ckimage=`podman images | grep 1_mongo`
  if [ -z "$ckimage" ]; then
    podman network create --subnet "$1.0/24" --gateway "$1.254" core
    podman network ls
    podman network inspect core 

    podman run -idt --restart="always" --privileged -v ./data:/data \
           --net core --ip "$1.1" --name tmp ubuntu:default /sbin/init

    podman cp ./coreimages/1_mongo/db-container.sh tmp:/
    podman exec -it tmp /bin/bash ./db-container.sh
    
    podman cp ./coreimages/1_mongo/start.sh tmp:/
    sleep 3

    podman cp ./coreimages/1_mongo/db-backup.sh tmp:/
    podman exec -it tmp /bin/bash ./db-backup.sh

    podman commit tmp 1_mongo:latest

    podman stop tmp && podman rm tmp

    net_name=`podman network ls | grep core | awk '{ print $2 }'`
    podman network rm ${net_name}
    podman network ls
  fi
}

run() {
  sysctl -w fs.inotify.max_user_instances=1024
  sctp_check
  echo "Create 5G network : Range $1.x/24, Bridge Slave NIC Name $2"
 
  # addalias=`cat /etc/profile | grep 'podman exec'`
  # if [ -z "$addalias" ]; then
  #   cat <<EOF>> /etc/profile
  #     alias core='podman exec -it'
  #     alias status='/bin/bash systemctl status xxxd'
  #   EOF
  # fi
  
  ckimage=`podman images | grep ubuntu:default`
  if [ -z "$ckimage" ]; then
    podman build -t ubuntu:default -f ./baseimage/containerfile
  fi 
  
  make_db_container "$1" "$2"

  cp -r ./coreimages coreimages-run
  sed -i "s/default_ip/$1/g" ./coreimages-run/*/*

  cp podman-compose.yml podman-compose.run.yml
  sed -i "s/default_network_name/core/g" ./podman-compose.run.yml
  sed -i "s/default_ip/$1/g" ./podman-compose.run.yml

  podman-compose -f podman-compose.run.yml up -d
  podman exec -it 1_mongo ./start.sh
  core_net_name=`podman network ls | grep core | awk '{ print $2 }'`
  pod_cni_nic=`podman network inspect $core_net_name | grep network_interface | awk '{ print $2 }'`
  nmcli con add type bridge-slave ifname "$2" master "${pod_cni_nic:1:-2}"
  podman exec -it 5_upf /bin/bash ./iptable-set.sh  

  echo && echo
  echo "################################################################################################################################################################"
  podman ps -a
  echo "################################################################################################################################################################"
  echo && echo
}

stop_n_remove() {
  echo
  podman ps -a
  podman-compose -f podman-compose.run.yml down
  rm -rf podman-compose.run.yml
  rm -rf ./coreimages-run
 
  core_net_name=`podman network ls | grep core | awk '{ print $2 }'` 
  slave_nic1=`nmcli con show | grep bridge-slave | awk '{ print $1 }'`
  slave_nic2=`podman network inspect $core_net_name | grep network_interface | awk '{ print $2 }'` 
  echo
  nmcli con show
  echo
  nmcli con del ${slave_nic1}
  nmcli dev del ${slave_nic2:1:-2}
  echo
  nmcli con show
  echo
  podman network rm ${core_net_name}
  echo
  podman network ls
  echo
  nmcli con show
  
  iptables -D INPUT 2
  iptables -D INPUT 1
  nmcli con del ogstun
  nmcli dev del ogstun
  nmcli con del upf
  nmcli dev del upf
  nmcli con show
  nmcli dev status
  iptables -L  
  echo && echo
  echo "############################################################################################################################################################"
  podman ps -a
  echo
  echo "############################################################################################################################################################"
  echo && echo
}

main() {
  net=''
  name=''
  while :; do
    case "${1-}" in
    -h | --help) usage ;;

    --no-color) NO_COLOR=1 ;;

    -net)
      net="${2-}"
      shift
      
      while :; do
        case "${3-}" in
        -name)
          name="${4-}"
          shift
          ;;
        -?*) die "Unknown option: $3" ;;
        *)break;;
        esac
      done
    ;;

    -name)
      name="${2-}"
      shift

      while :; do
        case "${3-}" in
        -net)
          net="${4-}"
          shift
          ;;
        -?*) die "Unknown option: $3" ;;
        *)break;;
        esac
      done
    ;;
    
    -rm)
      stop_n_remove "$1" "$2"
      exit
    ;;

    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  [[ -z "${net-}" ]] && die "${RED}Missing required parameter: 'net'.\nPlease check -h | --help option.${NOFORMAT}"
  [[ -z "${name-}" ]] && die "${RED}Missing required parameter: 'name'.\nPlease check -h | --help option.${NOFORMAT}"

  run ${net} ${name}

  return 0
}

setup_colors
main "$@"
