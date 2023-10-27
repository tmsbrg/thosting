#!/bin/bash

cmd="$1"

script="$(realpath "$0")"
projectpath="$(dirname "$script")"

# Load configs
source "$projectpath/editme.sh"

pb_api=$(head -1 ~/porkbun-apikey.txt)
pb_secret=$(tail -1 ~/porkbun-apikey.txt)

function usage {
    echo 'Thomas DNS script (tdns): Uses Porkbun to make, destroy or list subdomains.'
    echo
    echo 'Requirements: httpie'
    echo 'Configuration: set domain in editme.sh'
    echo
    echo 'Usage examples:'
    echo '    Create a subdomain A record called random1.<domain> and point it to 10.0.0.1:'
    echo '    tdns make random1 A 10.0.0.1'
    echo
    echo '    Same as above but with a specific ttl instead of default (default is set in editme.ssh):'
    echo '    tdns make random1 A 10.0.0.1 3600'
    echo
    echo '    List current subdomains:'
    echo '    tdns list'
    echo
    echo '    Destroy subdomain record'
    echo '    thosting destroy random1'
}

function make {
    subdomain="$1"
    type="$2"
    content="$3"
    ttl="$4"
    http -j https://porkbun.com/api/json/v3/dns/create/"$domain" secretapikey="$pb_secret" apikey="$pb_api" name="$subdomain" type="$type" content="$content" ttl="$ttl"
}

function list {
    http -j https://porkbun.com/api/json/v3/dns/retrieve/"$domain" secretapikey="$pb_secret" apikey="$pb_api"
}

function destroy {
    subdomain="$1"
    type="$2"
    http -j https://porkbun.com/api/json/v3/dns/deleteByNameType/"$domain"/"$type"/"$subdomain" secretapikey="$pb_secret" apikey="$pb_api"
}

case "$cmd" in
    make)
        subdomain="$2"
        type="$3"
        content="$4"
        ttl="${5:-"$ttl"}"
        echo "-- make $subdomain $type $content $ttl"
        make "$subdomain" "$type" "$content" "$ttl"
        ;;

    help)
        usage
        ;;

    list)
        list
        ;;

    destroy)
        subdomain="$2"
        type="${3:-"A"}"
        echo "-- destroy $subdomain $type"
        destroy "$subdomain" "$type"
        ;;

    *)
        echo "Unknown command $cmd"
        usage
        exit 1
        ;;
esac
