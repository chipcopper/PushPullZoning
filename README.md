#   pullZoning.bash
#   pushZoning.bash

This pair of bash scripts allows a user to copy zoning configuration information from one fabric to another using a local computer as an intermediary.
It can also be used to create a backup of a fabric's zoning configuration for restoration in case of corruption, loss, or inadvertent deviation.

pullZoning uses the Fabric OS API to pull aliases, zones, and configurations (configs) from a switch and stores them in JSON format on the local computer. 
It also retrieves the name of the currently active config.  pushZoning pushes the zoning configuration information found in these files to a switch optionally enabling the configuration that was in effect at the time of the pull.

These scripts use the jq utility to parse and trim the JSON data coming from the source switch.  
jq is open source and pre-compiled binaries are available at:

https://stedolan.github.io/jq/download/


Typical executions:

~~~
$ ./pullZoning.bash
PULL zoning information
Username: admin
Password:
IP Address: 10.1.2.3
Secure http (y/n) [n]:
Pull completed


$ ./pushZoning.bash
PUSH zoning information
Username: admin
Password:
IP Address: 192.168.4.5
Secure http (y/n) [n]:
Activate config (y/n) [y]:
Aliases pushed
Zones pushed
Configs pushed
Defined configuration saved and config activated
~~~
