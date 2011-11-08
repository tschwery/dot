#------------------------------------------
#------------  Navigation  ----------------
function up {
    path=""
    up="../"
    for (( i=1; i<=$1; i++))
    do
        path=$path$up
    done
    cd $path
    pwd
    return 0
}

#------------  Utilities  -----------------
function images_bigger {
    echo "Images in landscape format, bigger than 1280x800" >&2
    for i in *; do
        identify "$i" | awk '{print $3}' | perl -ne 'm/(\d+)x(\d+)/; if (($1 > 1280) && ($2 > 800) && ($1/$2 > 1)) { print "'"$i"'\n"; } else { print "'"$i"' too small ($1x$2)\n"; };' ; 
    done 2> /dev/null | grep -v "too small"
}

function gen_password {
    length=$1
    if [ -z "$length" ]; then length=10; fi
    head -c24 /dev/urandom | base64 | head -c $length | sed 's/$/\n/'
}

function reverse_md5 {
    hash=$1
    if [ -z "$hash" ]; then echo "Please give a hash ..."; return 1; fi
    curl "http://md5.noisette.ch/md5.php?hash=$hash"
}

function file_send {
    if [ $# -ne 3 ]; then echo "file_send dest_ip dest_port file" >&2; return 0; fi
    dest_ip=$1
    dest_port=$2
    file=$3
    pv $file | nc $dest_ip $dest_port
}

function file_receive {
    if [ $# -ne 2 ]; then echo "usage: file_receive listen_port file" >&2; return 0; fi
    port=$1
    file=$2
    nc -l -p $port | pv > $file
}

function folder_send {
    if [ $# -lt 2 ]; then echo "usage: folder_send dest_ip dest_port files" >&2; return 0; fi
    dest_ip=$1
    dest_port=$2
    shift
    shift
    size=$(du -s $@ | awk '{total += $1;}END{print total;}')
    echo $@ are $size
    tar cv $@ | pv -s ${size}k | nc $dest_ip $dest_port
}

#------------  Work utilities -------------
function zorglub {
    pushd .;
    cd /home/valdor/workspace/SNV3SRV/SNV3-cclient/Tools;
    for i in $@; do
        DOMAIN=$(echo $i | tr '[a-z]' '[A-Z]')
        ./create-config-zip --populate --host localhost:8181 --only-files ../Ressources/System\ texts/Tasks\ and\ DataFields/Ta*${DOMAIN}* ../Config/*${DOMAIN}*.xml ../Config/*/*${DOMAIN}*.xml;
    done;
    popd;
}

