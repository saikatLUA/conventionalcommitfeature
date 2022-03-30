#!/bin/bash
echo $0

# Source properties
source properties.sh

function test_in_docker {
    translated_proxy=${http_proxy/127.0.0.1/172.17.0.1}
    
    docker build \
        --build-arg HTTP_PROXY=$translated_proxy \
        --build-arg HTTPS_PROXY=$translated_proxy \
        --build-arg NO_PROXY="$no_proxy" \
        --build-arg http_proxy=$translated_proxy \
        --build-arg https_proxy=$translated_proxy \
        --build-arg no_proxy="$no_proxy" \
        -t robottest:latest -f Dockerfile .

    [[ "${INTERACTIVE_DOCKER:-"true"}" == "true" ]] && it="-it" || it=''

    docker run --rm ${it} -v ${PWD}:/app --network host --name wallbox_robottest robottest:latest bash -c "./$0 $1 $2"

    exit $?
}


if [[ "$TEST_IN_DOCKER" == "true" ]];then
    if [[ "$1" == "robottest" ]];then
        test_in_docker $@
    fi
fi

if [[ "$1" == "robottest" ]];then
    no_proxy="localhost,127.0.0.1" robot --exclude disabled --nostatusrc --outputdir results --listener oxygen.listener tests/ 
    echo "Test completed."
    
elif [[ "$1" == "deploy" ]];then
    set -x

    # set the PACKAGE_VERSION to '<releaseversion>' when not set
    : ${RELEASE_VERSION:="0"}
    : ${PACKAGE_VERSION:="${RELEASE_VERSION}"}

    results_dir="results"
    reports_dir="reports"    
    ls -a $results_dir

    if [[ -d "$results_dir" ]];then
        tar_name="${PACKAGE_NAME}-${PACKAGE_VERSION}"
        mkdir -p "$reports_dir/${tar_name}"
        cp ${results_dir}/* "$reports_dir/${tar_name}/"
        (cd $reports_dir && tar -zcvf "${tar_name}.tar.gz"   "${tar_name}/")
        rm -rf "$reports_dir/${tar_name}/"
        ls -a $reports_dir
    else
        echo "WARN: Testresults directory are not present"
        exit 1
    fi
    
    echo -e "Upload to Artifactory"
    if [[ -z ${LOGIN_USR} || -z ${ARTIFACTORY_TOKEN} ]];then
        echo "ERROR: Please set ARTIFACTORY_LOGIN and ARTIFACTORY_TOKEN!"
        exit 1
    fi

    ./deploy-to-artifactory.sh "$reports_dir"

fi
