#!/bin/bash
#### embedded-linux-pipeline deploy script v0.0.1

# Recursively deploys folder content. Attempt checksum deploy first to optimize upload time.
# i.e. only uploads new artifacts, skiping the upload if the file exists in artifactory.
# Original source:
#    - https://jfrog.com/blog/artifactory-command-line-interface-cli-pure-and-simple/ (chapter: The power of CLI - Let’s see another Example)
#    - https://github.com/JFrog/project-examples/blob/master/bash-example/deploy-folder-by-checksum.sh

# WARNING: this works, but needs a lot of improvements!
set -x
# Source properties
source properties.sh

repo_url="${REPO_SERVER_URL}"
tgt_repo="${TARGET_REPO}"
user="${LOGIN_USR}"
pass="${ARTIFACTORY_TOKEN}"


dir="$1"

if [ -z "$dir" ]; then echo "Please specify a directory to recursively upload from!"; exit 1; fi

if [ ! -x "`which sha1sum`" ]; then echo "You need to have the 'sha1sum' command in your path."; exit 1; fi
# Upload by checksum all files from the source dir to the target repo
find "$dir" -type f | sort | while read f; do
    filter_applied=false
    for t in ${REPO_UPLOAD_FILTER[@]}; do
        if echo "$f" | grep --quiet -P "$t"; then
            filter_applied=true
            break
        fi
    done

    if [ "$filter_applied" = true ] ; then
        printf "\n\nNot Uploading '$f'"
        continue
    fi

    rel="$(echo "$f" | sed -e "s#$dir##" -e "s# /#/#")";
    sha1=$(sha1sum "$f")
    sha1="${sha1:0:40}"
    printf "\n\nUploading '$f' (cs=${sha1}) to '${repo_url}/${tgt_repo}/${rel}'"

    if [[ $f == *"build/artifacts"* ]]; then
      echo "<a href=\"${repo_url}/${tgt_repo}/${rel}\">$f</a><br>" >> artifactory_links.html
    fi

    status=$(curl -k -u $user:$pass -X PUT -H "X-Checksum-Deploy:true" -H "X-Checksum-Sha1:$sha1" --write-out %{http_code} --silent --output /dev/null "${repo_url}/${tgt_repo}/${rel}")
    echo "status=$status"
    # No checksum found - deploy + content
    [ ${status} -eq 404 ] && {
        curl -k -u $user:$pass -H "X-Checksum-Sha1:$sha1" -T "$f" "${repo_url}/${tgt_repo}/${rel}"
    }
done
rc="$?"
echo -e "\nUpload return code was: ${rc}"
[[ "${rc}" == "0" || "${rc}" == "404" || "${rc}" == "201" ]] && exit 0 || exit 1 ## TODO: improve error detection
