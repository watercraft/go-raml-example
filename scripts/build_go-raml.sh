#!/bin/bash

# This script builds zwsd container image

set -x
set -e

PROG=${0##*/}

usage() {
    echo "Usage: $PROG [-r <build id>] [-g <go path>] [-b <branch> ] [-B <baseos_vers>] [-o] [-u] [-P] [TAG] [-a]" 1>&2
    exit 1
}

# SET TAG
function set_tag {
        if [ "${TAG}" == "" ]; then
                git checkout ${BRANCH}
        else
                git checkout tags/${TAG}
        fi
}

main() {
    local DO_PUSH=true
    local DO_UPDATE=false
    local ONLY_ZWSD=false
    local PATCH_ATHENA=false
    local SUDO=${SUDO:-sudo}
    export BUILDID=`date '+%Y%m%d%H%M%S'`
    export BRANCH=master
    while getopts "b:B:g:oPr:ua" opt; do
          case $opt in
              b) BRANCH=$OPTARG ;;
              B) BASEOS_VERS=$OPTARG ;;
              g) GOPATH=$OPTARG ;;
              o) ONLY_ZWSD=true ;;
              P) DO_PUSH=false ;;
              r) export BUILDID=$OPTARG ;;
              u) DO_UPDATE=true ;;
              a) PATCH_ATHENA=true ;;
              *) usage ;;
          esac
    done

    shift $((OPTIND -1))
    export TAG=$1

    local BASEOS_VERS="${BASEOS_VERS:-$BUILDID}"

    # PROJECT DIR
    #
    export PROJECT=github.com/watercraft

    export GOPATH=${GOPATH:-${HOME}/go}
    if ! $DO_UPDATE; then
        ${SUDO} rm -rf ${GOPATH}
        mkdir -p ${GOPATH}/src/${PROJECT}
    fi

    export PATH=${GOPATH}/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

    cd ${GOPATH}/src/${PROJECT}

        # GO-RAML
        #

        cd ${GOPATH}/src/${PROJECT}
        $DO_UPDATE || git clone https://${PROJECT}/go-raml.git
        cd go-raml
        git pull
        set_tag
        make install

        # GO-RAML-EXAMPLE
        #

        cd ${GOPATH}/src/${PROJECT}
        $DO_UPDATE || git clone https://${PROJECT}/go-raml-example.git
        cd go-raml-example
        git pull
        set_tag
        go-raml server --language go --kind static --dir server --no-apidocs --ramlfile example.raml

}

main "$@"
