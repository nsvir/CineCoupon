#!/bin/bash

source $(dirname $0)/credentials

function notify() {
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -en "${RED}"
    echo -en $@
    echo -en "${NC}"
}

COOKIE=/tmp/cookies
CURL_OUTPUT=/tmp/index.html
function CURL() {
    STATUS_CODE=$(curl -s -b $COOKIE -c $COOKIE -o $CURL_OUTPUT -A "Mozilla/5.0 (X11; Linux i686; rv:64.0) Gecko/20100101 Firefox/64.0" -w "%{http_code}" $@)
    echo " $STATUS_CODE"
}

set -e                                                       #abort script if any command fails

function logingIn() {
    notify "Request orange.fr"
    CURL "https://login.orange.fr/"

    notify "Request Login"
    CURL --data '{"login":"'$ORANGE_LOGIN'"}' "https://login.orange.fr/front/login"

    # Extracting loginEncrypt
    LOGIN_ENCRYPT=$(cat $CURL_OUTPUT)
    LOGIN_ENCRYPT=${output##*loginEncrypt\\\":\\\"}
    LOGIN_ENCRYPT=${output%%\\\"*}

    notify -n "Connecting.. "
    CURL --data '{"loginEncrypt":"'$LOGIN_ENCRYPT'","password":"'$ORANGE_PASSWORD'"}' "https://login.orange.fr/front/password"
}

function util_extract_div() {
    RESULT=$(cat $CURL_OUTPUT)
    RESULT=${RESULT##*$1\"\>}
    RESULT=${RESULT%%</div>*}
    echo $RESULT
}

function askCoupon() {
    notify "Request cineday"
    CURL "https://mdsp.orange.fr/cineday/commande/loadingWebPage"

    notify -n "Fetching coupon.. "
    CURL --data 'portefeuilleId=0' "https://mdsp.orange.fr/cineday/commande/pinRequestWeb"

    if [[ "$(cat $CURL_OUTPUT)" == *"errorBox"* ]]
    then
	echo $(util_extract_div "errorBox")
    else
	echo $(util_extract_div "imageCodeUsed")
    fi
}

function cleaning() {
    rm -f $COOKIE
    rm -f $CURL_OUTPUT
}

logingIn
askCoupon
cleaning
exit 0
