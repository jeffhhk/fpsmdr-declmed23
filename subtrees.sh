
fatal() {
    echo "$1" 1>&2
    echo invalid configuration, exiting 1>&2
}

subtrees-check-config() {
    if [[ "$prefixRemote" == "" ]]
    then
        fatal "required variable: prefixRemote"
        return 1
    elif [[ "$suffixRemote" == "" ]]
    then
        fatal "required variable: suffixRemote"
        return 1
    else
        return 0
    fi
}

subtrees-init() {
    nameRemote="$1"
    pathRemote="$2"
    pathLocal="$3"
    if ! git remote show ${nameRemote} 1>&- 2>&-
    then
        git remote add ${nameRemote} "${prefixRemote}${pathRemote}${suffixRemote}"
    else
        git remote set-url ${nameRemote} "${prefixRemote}${pathRemote}${suffixRemote}"
    fi
    git fetch ${nameRemote}
    git subtree add --prefix ${pathLocal} ${nameRemote} master
}

subtrees-pull() {
    nameRemote="$1"
    pathRemote="$2"
    pathLocal="$3"
    git subtree pull --prefix ${pathLocal} ${nameRemote} master
}