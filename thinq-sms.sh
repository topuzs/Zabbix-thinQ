#!/bin/bash

function usage
{
	if [ -n "$1" ]; then echo $1; fi
	echo "Usage: twilio-sms.sh <toDID> <subject> <message>"
	echo $1
	exit 1
}

VERBOSE=0

PHONE=$1
ZBX_SUBJECT=$2
ZBX_MESSAGE=$3

CONFIGFILE="./thinq-sms.conf"

# test configfile
 if [ -n "$CONFIGFILE" -a ! -f "$CONFIGFILE" ]; then echo "Configfile not found: $CONFIGFILE"; usage; fi

# # source configfile if given
 if [ -n "$CONFIGFILE" ]; then . "$CONFIGFILE";
 fi

# verify params
if [ -z "$USERNAME" ]; then usage "Username not set, it must be provided in the config file, or on the command line."; fi;
if [ -z "$TOKEN" ]; then usage "Token not set, it must be provided in the config file, or on the command line."; fi;
if [ -z "$ACCOUNTID" ]; then usage "AccountId not set, it must be provided in the config file, or on the command line."; fi;
if [ -z "$FROM_DID" ]; then usage "From-Did not set, it must be provided in the config file, or on the command line."; fi;
if [ -z "$MESSAGE_ARG" ]; then usage "Message not set, it must be provided on the command line."; fi;

AUTH=$(echo -ne "$USERNAME:$TOKEN" | base64 --wrap 0)
MESSAGE=`echo "$ZBX_SUBJECT"\n"$ZBX_MESSAGE"`
RETURN=0

echo "$(date '+%Y/%m/%d %H:%M:%S') - Sending SMS to $PHONE from $FROM_DID..." >> /tmp/thinq_result.log

# initiate a curl request to the thinQ REST API, to begin a phone call to that number
RESPONSE=`curl -s -o /dev/null -w '%{http_code}'  --header "Authorization: Basic $AUTH" --location -g --request POST "https://api.thinq.com/account/$ACCOUNTID/product/origination/sms/send" --data-raw '{"from_did":"'"$FROM_DID"'","to_did":"'"$PHONE"'","message":"'"$MESSAGE"'"}'`
if [ $RESPONSE -eq 200 ]; then
	echo "$(date '+%Y/%m/%d %H:%M:%S') - Successfully sent SMS to $PHONE from $FROM_DID" >> /tmp/thinq_result.log
	exit 0
else
	echo "$(date '+%Y/%m/%d %H:%M:%S') - Couldn't send SMS to $PHONE from $FROM_DID" >> /tmp/thinq_result.log
	echo "$(date '+%Y/%m/%d %H:%M:%S') - Got $RESPONSE from command: curl -s -o /dev/null -w '%{http_code}'  --header \"Authorization: Basic $AUTH\" --location -g --request POST \"https://api.thinq.com/account/$ACCOUNTID/product/origination/sms/send\" --data-raw '{\"from_did\":\"'\"$FROM_DID\"'\",\"to_did\":\"'\"$PHONE\"'\",\"message\":'$MESSAGE\"'}'" >> /tmp/thinq_result.log
	exit 2
fi