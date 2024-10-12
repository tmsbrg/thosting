#!/bin/bash

cmd="$1"
name="$2"
playbook="$3"

tag_name="thosting"
playbook_wait_time=1m

script="$(realpath "$0")"
projectpath="$(dirname "$script")"

# Load configs
source "$projectpath/editme.sh"

playbooks_dir="$projectpath"/playbooks

pb_api=$(head -1 ~/porkbun-apikey.txt)
pb_secret=$(tail -1 ~/porkbun-apikey.txt)

function usage {
    echo 'Thomas Hosting script: Thomas in the Clouds (With Diamonds)'
    echo 'Uses DigitalOcean and Porkbun APIs to create servers and give instantly give them a subdomain'
    echo 'Also optionally uses Ansible to set them up with software (currently only supports xsshunter, playbook included!)'
    echo
    echo 'Requirements: ansible, httpie, doctl'
    echo
    echo "First time setup: first, edit editme.sh to set domain to a domain you control that's managed by Porkbun."
    echo '    then, create a PAT for DigitalOcean and authenticate to DigitalOcean with `doctl auth init`'
    echo '    then, link an SSH key to your DigitalOcean account and find its ID with `doctl compute ssh-key list`, edit editme.sh and set ssh_key to this.'
    echo '    create an API key for the Porkbun API and save it in ~/porkbun-apikey.txt (first line API key, second line secret key)'
    echo '    For xsshunter playbook: Be sure to edit editme.sh to add your own email address there'
    echo
    echo 'Usage examples:'
    echo '    Create a new VM and link random1.<domain> subdomain to it:'
    echo '    thosting make random1'
    echo
    echo '    List current VMs:'
    echo '    thosting list'
    echo
    echo '    Use xsshunter ansible playbook on the domain to deploy XSS hunter:'
    echo '    thosting config random1 xsshunter'
    echo
    echo '    Create a VM at xss.<domain> and immediately set it up with the xsshunter ansible playbook (same as make and then config but in one command):'
    echo '    thosting make xss xsshunter'
    echo
    echo '    Destroy created VM and the subdomain link'
    echo '    thosting destroy random1'
}

function get_newest_lts_ubuntu {
    echo "-- Finding newest LTS Ubuntu image on DigitalOcean..." 1>&2
    image_line="$(doctl compute image list-distribution | grep -w Ubuntu | grep -w LTS | sort -n | tail -1 || exit 1)"
    if [ -z "$image_line" ]; then
        echo "-- ERROR: Cannot find Ubuntu LTS image, check code" 1>&2
        exit 1
    fi
    echo "-- Found: $image_line" 1>&2
    printf "%s" $(cut -d' ' -f1 <<< "$image_line")
}

function make {
    name="$1"
    image="$(get_newest_lts_ubuntu)"
    echo "-- Making $name droplet on Digital Ocean and waiting for IP address..." 1>&2
    doctl compute droplet create "$name" --tag-name "$tag_name" --region ams3 --ssh-keys "$ssh_key" --size s-1vcpu-2gb-70gb-intel --image "$image" --wait || exit 1
    echo "-- Getting IP address..." 1>&2
    ip=$(doctl compute droplet get "$name" --format PublicIPv4 --no-header)
    echo "-- Adding $name.$domain subdomain on Porkbun..." 1>&2
    http -j https://api.porkbun.com/api/json/v3/dns/create/"$domain" secretapikey="$pb_secret" apikey="$pb_api" name="$name" type=A content="$ip" ttl="$ttl"
    echo "-- Creating $name.hosts file for Ansible..." 1>&2
    echo "$name.$domain" > "$projectpath/$name.hosts" 1>&2
}

function config {
    name="$1"
    playbook="$2"
    echo "-- Running playbook $playbook..." 1>&2
    if [ '!' -d "$playbooks_dir/$playbook" ]; then
        echo "-- ERROR: Cannot find playbook $playbook!" 1>&2
        exit 2
    fi
    ansible-playbook -e mail="$mail" --verbose -i "$projectpath/$name.hosts" "$playbooks_dir/$playbook/main.yml"
}

function list {
    doctl compute droplet list --tag-name "$tag_name"
}

function destroy {
    name="$1"
    echo "-- Destroying droplet" 1>&2
    doctl compute droplet delete "$name" -f
    echo "-- Removing subdomain" 1>&2
    http -j https://api.porkbun.com/api/json/v3/dns/deleteByNameType/"$domain"/A/"$name" secretapikey="$pb_secret" apikey="$pb_api"
    echo "-- Removing ansible hosts file" 1>&2
    rm "$projectpath/$name.hosts"
}

case "$cmd" in

    make)
        echo "-- make $name" 1>&2
        make "$name"
        if [ '!' -z "$playbook" ]; then
            echo "-- Waiting $playbook_wait_time for droplet to be ready..." 1>&2
            sleep "$playbook_wait_time"
            config "$name" "$playbook"
        fi
        ;;

    config)
        echo "-- config $name $playbook" 1>&2
        config "$name" "$playbook"
        ;;

    help)
        usage
        ;;

    list)
        list
        ;;

    destroy)
        echo "-- destroy $name" 1>&2
        destroy "$name"
        ;;

    *)
        echo "Unknown command $cmd" 1>&2
        usage
        exit 1
        ;;
esac
