#!/usr/bin/env bash
# pushZoning.bash
# Version 1.0
# Author: Chip Copper
#
# This script pushes aliases, zones, and configs to a switch from
# local files.  It can be used to restore configurations to a switch
# as a form of restore operation or can serve to duplicate zoning on
# another fabric.

echo "PUSH zoning information"
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
#PASSWORD='Password'
#IPADDRESS='192.168.4.100'

NEWCONFIG="Y"
read -p "Activate config (y/n) [y]: " NEWPROTO
if [[ "$NEWPROTO" == "n" ]] || [[ "$NEWPROTO" == "N" ]];
then
	NEWCONFIG="N"
fi

URI='running/brocade-zone/defined-configuration'
URI2='running/brocade-zone/effective-configuration'

# Establish a session with the switch and keep the credentials
export SANSESSION=$(curl -s -I -X POST -u "$USERNAME:$PASSWORD" $PROTO://$IPADDRESS/rest/login | grep "Authorization" | tr -d "\r\n")

# Get the current configuration checksum
export CHECKSUM=$(curl -s -H "$SANSESSION" -H "Content-Type: application/yang-data+json" -H "Accept: application/yang-data+json" $PROTO://$IPADDRESS/rest/$URI2/checksum \
| jq '.Response."effective-configuration" | {checksum: .checksum}')

# Push aliases
grep -q "null$" aliases.json
if  (( $? )) ; 
then
    curl -s -X POST -H "$SANSESSION" -H "Content-Type: application/yang-data+json" -H "Accept: application/yang-data+json" --data @aliases.json $PROTO://$IPADDRESS/rest/$URI/alias
    echo "Aliases pushed"
else
    echo "No aliases to push."
fi

# Push zones

# Push zones
grep -q "null$" zones.json
if  (( $? )) ; 
then
	curl -s -X POST -H "$SANSESSION" -H "Content-Type: application/yang-data+json" -H "Accept: application/yang-data+json" --data @zones.json $PROTO://$IPADDRESS/rest/$URI/zone
	echo "Zones pushed"
else
    echo "No zones to push."
fi


# Push configs
grep -q "null$" cfgs.json
if (( $?  )); 
then
	curl -s -X POST -H "$SANSESSION" -H "Content-Type: application/yang-data+json" -H "Accept: application/yang-data+json" --data @cfgs.json $PROTO://$IPADDRESS/rest/$URI/cfg
	echo "Configs pushed"
else
    echo "No configs to push."
fi


# Push active config
if [[ "$NEWCONFIG" == "Y" ]];
then
	grep -q "null$" active.data
	if (( $?  ));
	then
	    export CFGNAME=$(cat active.data)
	    curl -s -X PATCH -H "$SANSESSION" -H "Content-Type: application/yang-data+json" -H "Accept: application/yang-data+json" --data "$CHECKSUM" $PROTO://$IPADDRESS/rest/$URI2/cfg-name/$CFGNAME
	    echo "Defined configuration saved and config activated"
	else
		curl -s -X PATCH -H "$SANSESSION" -H "Content-Type: application/yang-data+json" -H "Accept: application/yang-data+json" --data "$CHECKSUM" $PROTO://$IPADDRESS/rest/$URI2/cfg-action/1
		echo "No active config at source, defined configuration saved"
	fi
else
	curl -s -X PATCH -H "$SANSESSION" -H "Content-Type: application/yang-data+json" -H "Accept: application/yang-data+json" --data "$CHECKSUM" $PROTO://$IPADDRESS/rest/$URI2/cfg-action/1
	echo "No active config at source, defined configuration saved"
fi

# End the session.
curl -s -X POST -H "$SANSESSION" $PROTO://$IPADDRESS/rest/logout
