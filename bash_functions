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
