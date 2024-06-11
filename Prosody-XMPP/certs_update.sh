#!/bin/sh
# Author: devnull (Rafael Grether)
# Yes, you can use prosodyctl import proccess, but...no.
#

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

# Since Prosody XMPP is inside the FreeBSD Jail and the certificate is on another host,
# I'm using null file system to mountpoint the host certificates.
# On GNU/Linux, the origin path should be /etc/letsencrypt/archive/<certname>/
PATH_ORIGIN_CERTS=/nullfs_certs

#On GNU/Linux, the prosody prefix config path probably should be /etc/prosody/
PATH_PROSODY_CERTS=/usr/local/etc/prosody/certs
PROSODY_CONF_FILE=/usr/local/etc/prosody/prosody.cfg.lua

# I'm copying the certificates from the Origin to the Prosody certificates directory.
rsync -av $PATH_ORIGIN_CERTS/ $PATH_PROSODY_CERTS/ > /root/certs_update.log

# Look for new 'fullchain' rsynched.
if grep -q "fullchain" /root/certs_update.log; then
	
	# Identifying the fullchain's name
	last_pem=$(ls -t $PATH_PROSODY_CERTS/fullchain*.pem | head -n 1)
	num_pem=$(echo "$last_pem" | sed 's/.*fullchain\([0-9]*\)\.pem/\1/')

	new_cert_pem="$PATH_PROSODY_CERTS/fullchain$num_pem.pem"
	new_cert_key="$PATH_PROSODY_CERTS/privkey$num_pem.pem"

	# Replace certificate PATH in prosody.cfg.lua
	# SED command on GNU/Linux is a little bit different, so google it! (or EDIT ME)
	sed -i '' "s|certificate = \".*\";|certificate = \"$new_cert_pem\";|" $PROSODY_CONF_FILE
	sed -i '' "s|key = \".*\";|key = \"$new_cert_key\";|" $PROSODY_CONF_FILE
	
	# Fix permission
	chown prosody:prosody $PATH_PROSODY_CERTS/*.pem
	chmod 600 $PATH_PROSODY_CERTS/*.pem

	# Restarting Prosody
	# On GNU/Linux, well, it depends on your init system, so edit this line properly
	service prosody restart

	# Sending mail
	# I'm using aws ses to send mails, but you can create your own mail script using curl or sendmail/postfix
	aws ses send-email \
        --from "REDACTED NAME <noreply@REDACTED.mail>" \
        --destination "ToAddresses=devnull@apt322.org" \
        --message "Subject={Data='Prosody XMPP Server certificate updated'},Body={Html={Data='The new Prosody XMPP certificate was generated on $new_cert_pem . Check your Prosody XMPP Server, if it still functional.'}}" --configuration-set REDACTED
	exit 0
fi

