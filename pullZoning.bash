#!/usr/bin/env bash
# pullZoning.bash
# Version 1.0
# Author: Chip Copper
#
# This script pulls aliases, zones, and configs from a switch and
# stores them in local files.  These files can either serve as backups
# or can be pushed to other fabrics using the companion script pushZoning.bash


# Make sure jq is installed
command -v jq >/dev/null 2>&1
if (( $? != 0 ));
then
	echo "This script requires jq."
	echo "jq is a JSON parser that removes a wrapper from the API response."
	echo "Instructions for getting and installing it can be found at"
	echo "https://stedolan.github.io/jq/download/"
	exit 1
fi

echo "PULL zoning information"
read -p "Username: " USERNAME
read -p "Password: " -s PASSWORD
echo ""
read -p "IP Address: " IPADDRESS

PROTO='http'

NEWPROTO="X"
read -p "Secure http (y/n) [n]: " NEWPROTO
if [[ "$NEWPROTO" == "y" ]] || [[ "$NEWPROTO" == "Y" ]];
then
	PROTO='https'
fi

# Testing defaults
#USERNAME='admin'
#PASSWORD='Pass@word1!'
#IPADDRESS='10.155.2.83'


URI='running/brocade-zone/defined-configuration/'
URI2='running/brocade-zone/effective-configuration/'

# Establish a session with the switch and keep the credentials
export SANSESSION=$(curl -s -I -X POST -u "$USERNAME:$PASSWORD" $PROTO://$IPADDRESS/rest/login | grep "Authorization" | tr -d "\r\n")

# Pull aliases
curl -s -H "$SANSESSION" -H "Accept: application/yang-data+json" $PROTO://$IPADDRESS/rest/$URI/alias | jq .Response > aliases.json

# Pull zones
curl -s -H "$SANSESSION" -H "Accept: application/yang-data+json" $PROTO://$IPADDRESS/rest/$URI/zone | jq .Response > zones.json

# Pull configs
curl -s -H "$SANSESSION" -H "Accept: application/yang-data+json" $PROTO://$IPADDRESS/rest/$URI/cfg | jq .Response > cfgs.json

# Pull active config
curl -s -H "$SANSESSION" -H "Accept: application/yang-data+json" $PROTO://$IPADDRESS/rest/$URI2/ | jq -r '.Response."effective-configuration"."cfg-name"' > active.data

# End the session.
curl -s -X POST -H "$SANSESSION" $PROTO://$IPADDRESS/rest/logout

echo "Pull completed"
