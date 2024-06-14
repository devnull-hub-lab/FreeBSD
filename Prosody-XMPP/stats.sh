#!/bin/sh
# Author: devnull (Rafael Grether)
# Send Prosody XMPP status by email
#

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

{
	echo -e "XMPP Server Stat - " "$(date)\r\n"

	echo -e "Version: " "$(prosodyctl shell 'server:version()')\r\n"

	echo -e "Uptime: " "$(prosodyctl shell 'server:uptime()')\r\n"

	echo -e "Memory Use: " "$(prosodyctl shell 'server:memory()')\r\n"

	echo -e "Active Components:\r\n"
	prosodyctl shell 'host:list()'
	echo -e "\r\n"

	echo -e "Rooms on the server:"
	prosodyctl shell 'muc:list("conference.xmppbrasil.net")'
	echo -e "\r\n"

	echo -e "List Users:\r\n"
	prosodyctl shell 'user:list("xmppbrasil.net", ".*")'
} > /tmp/stats.log

email_text=$(cat /tmp/stats.log)

aws ses send-email \
        --from "devnull <noreply@apt322.org>" \
        --destination "ToAddresses=devnull@apt322.org" \
        --message "Subject={Data='Biweekly Updates - XMPP'},Body={Text={Data='$email_text'}}"

