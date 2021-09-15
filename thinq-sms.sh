#!/bin/bash

function usage
{
	if [ -n "$1" ]; then echo $1; fi
	echo "Usage: twilio-sms [-v] [-c configfile] [-f from-did] [-u username] [-t token] [-a accountid] -m message number [number[number...]]"
	echo $1
	exit 1
}

VERBOSE=0

while getopts ":vc:f:u:t:a:m:" opt; do
	case "$opt" in
		c) CONFIGFILE=$OPTARG ;;
		f) FROM_DID_ARG=$OPTARG ;;
		u) USERNAME_ARG=$OPTARG ;;
		t) TOKEN_ARG=$OPTARG ;;
		a) ACCOUNTID_ARG=$OPTARG ;;
		m) MESSAGE_ARG=$OPTARG ;;
		v) VERBOSE=1 ;;
		*) echo "Unknown param: $opt"; usage ;;
	esac
done
shift $((OPTIND-1)) 

# test configfile
if [ -n "$CONFIGFILE" -a ! -f "$CONFIGFILE" ]; then echo "Configfile not found: $CONFIGFILE"; usage; fi

# source configfile if given
if [ -n "$CONFIGFILE" ]; then . "$CONFIGFILE";
# source the default ~/.twiliorc if it exists
# elif [ -f ~/.twiliorc ]; then . ~/.twiliorc;
fi

# if USERNAME, TOKEN, or FROM_DID were given in the commandline, then override that in the configfile
if [ -n "$USERNAME_ARG" ]; then USERNAME=$USERNAME_ARG; fi
if [ -n "$TOKEN_ARG" ]; then TOKEN=$TOKEN_ARG; fi
if [ -n "$ACCOUNTID_ARG" ]; then ACCOUNTID=$FROM_DID_ARG; fi
if [ -n "$FROM_DID_ARG" ]; then FROM_DID=$FROM_DID_ARG; fi

# verify params
if [ -z "$USERNAME" ]; then usage "Username not set, it must be provided in the config file, or on the command line."; fi;
if [ -z "$TOKEN" ]; then usage "Token not set, it must be provided in the config file, or on the command line."; fi;
if [ -z "$ACCOUNTID" ]; then usage "AccountId not set, it must be provided in the config file, or on the command line."; fi;
if [ -z "$FROM_DID" ]; then usage "From-Did not set, it must be provided in the config file, or on the command line."; fi;
if [ -z "$MESSAGE_ARG" ]; then usage "Message not set, it must be provided on the command line."; fi;

AUTH=$(echo -ne "$USERNAME:$TOKEN" | base64 --wrap 0)
MESSAGE=`echo $MESSAGE_ARG`
RETURN=0

# for each remaining shell arg, that's a phone number to call
for PHONE in "$@"; do
	echo "$(date '+%Y/%m/%d %H:%M:%S') - Sending SMS to $PHONE from $FROM_DID..." >> /tmp/thinq_result.log
	# initiate a curl request to the thinQ REST API, to begin a phone call to that number
	RESPONSE=`curl -s -o /dev/null -w '%{http_code}'  --header "Authorization: Basic $AUTH" --location -g --request POST "https://api.thinq.com/account/$ACCOUNTID/product/origination/sms/send" --data-raw '{"from_did":"'"$FROM_DID"'","to_did":"'"$PHONE"'","message":"'"$MESSAGE"'"}'`
	if [ $RESPONSE -eq 200 ]; then
		echo "$(date '+%Y/%m/%d %H:%M:%S') - Successfully sent SMS to $PHONE from $FROM_DID" >> /tmp/thinq_result.log
		RETURN=$[RETURN+0];
	else
		echo "$(date '+%Y/%m/%d %H:%M:%S') - Couldn't send SMS to $PHONE from $FROM_DID" >> /tmp/thinq_result.log
		echo "$(date '+%Y/%m/%d %H:%M:%S') - Got $RESPONSE from command: curl -s -o /dev/null -w '%{http_code}'  --header \"Authorization: Basic $AUTH\" --location -g --request POST \"https://api.thinq.com/account/$ACCOUNTID/product/origination/sms/send\" --data-raw '{\"from_did\":\"'\"$FROM_DID\"'\",\"to_did\":\"'\"$PHONE\"'\",\"message\":'$MESSAGE\"'}'" >> /tmp/thinq_result.log
		RETURN=$[RETURN+1];
	fi
done

if [ $RETURN -eq 0 ] ; then exit 0 ; else exit 2 ; fi