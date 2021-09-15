# Zabbix-ThinQ.sh

This is a set of scripts that will allow you to send SMS messages for zabbix alerts using thinQ. It will also allow you to rotate SMS in weekely schedule.

The script uses [thinQ](https://apidocs.thinq.com/) API to send SMS. You can check out API documentation if you want to improve these scripts.



## The scripts

##### thinq-sms.sh

This is the primary script for sending messages via thinq api. You need edit ``thinq-sms.conf`` file or specify required parameters on the command line.

``Usage: "twilio-sms.sh [-v] [-c configfile] [-f from-did] [-u username] [-t token] [-a accountid] <-m message> <number> [number[number...]]"``

  

##### schedule.sh

This script creates the schedule based on the list of phone numbers in ``schedule.conf``.

``Usage: schedule.sh [-v] [-c configfile]``

This script creates a Schedule directory. It creates 52 files (one for each week of the year) and cycles through the comma delimited list of phone numbers in the schedule.conf and adds a number to each file. To manually make changes to the schedule simply edit the file and change the phone number.

  

##### thinq-alert.sh

This script can be used if schedule is preferred or for a single number designated to receive messages. Edit the ``twilio-alert.conf`` file and add your phone number and weekly schedule preference. If you set ``UseWeeklySchedule = 0`` then the schedule is ignored and all alerts go to the "OnCallNumber".

``Usage: thinq-alert.sh [-v] [-c configfile]``  

##### thinq-alert-escalate.sh

This script should only be used when ``UseWeeklySchedule = 1``. It is designed to use in a zabbix [escalation](https://www.zabbix.com/documentation/3.2/manual/config/notifications/action/escalations). It will figure out who is on call next and send the message to them. This could be used in a scenario like "If "on call tech" doesn't acknowledge alert within 15 minutes then escalate to "next on call tech".

 ``Usage: twilio-alert-escalate.sh [-v] [-c configfile]`` 

##### thinq-alert-notify.sh

If you are using schedule and want to notify the next "on call tech" that they are about to go on call create a cron job that runs this script. It will only execute on Sunday regardless of what day it's run. (Unix weeks start on Monday, so Sunday is the end of the week) 

``Usage: thinq-alert-notify.sh [-v] [-c configfile]``

It will send a message like:
```

You will be on call tomorrow (08/14/17) at 12:01 AM. Please plan to respond to any alerts for the next 7 days.

```

  

## Installation

#### Scenario 1: Select Notify Users from Zabbix 

1. Copy thinq-sms.conf and  thinq-sms.sh into your zabbix alert scripts folder (normally located in ``/usr/lib/zabbix/alertscripts``)

2. Edit the thinq-sms.conf file and include your thinQ username, token, account id and phone number. Test the thinq-sms script to make sure it works, if below command writes 0, script is working;

```

/usr/lib/zabbix/alertscripts/thinq-sms.sh -c /usr/lib/zabbix/alertscripts/thinq-sms.conf -m "Test Message" 5555555555

echo $?

```

3. Change the owner and group of all scripts and directories to zabbix.

  

```chown -R zabbix:zabbix /usr/lib/zabbix/alertscripts```

5. Create your media type in Zabbix and point it at the script as below;

- Name: `thinQ SMS`
- Type: `Script`
- Script name: `thinq-sms.sh`
- Script parameters:
	- `-c/usr/lib/zabbix/alertscripts/thinq-sms.conf`
	- `-m{ALERT.MESSAGE}`
	- `{ALERT.SENDTO}`
	- `Enabled: True`

![thinq-sms sh-mediatype](https://user-images.githubusercontent.com/7428453/133491073-e2405d39-7890-47e4-9842-8463f8fd6326.png)



6. Create an action that uses at least your new media type named `thinQ SMS`.

7. You can optionally create escalations described in [escalations](https://www.zabbix.com/documentation/current/manual/config/notifications/action/escalations) document.

#### Scenario 1: Use Weekly Schedule and Rotate Numbers 

1. Copy all scripts and conf files  into your zabbix alert scripts folder (normally located in ``/usr/lib/zabbix/alertscripts``)

2. Edit the thinq-sms.conf file and include your thinQ username, token, account id and phone number. Test the thinq-sms script to make sure it works, if below command writes 0, script is working;

```

/usr/lib/zabbix/alertscripts/thinq-sms.sh -c /usr/lib/zabbix/alertscripts/thinq-sms.conf -m "Test Message" 5555555555

echo $?

```

3. Edit the schedule.conf file and run ``schedule.sh -v``

Change the owner and group of all scripts and directories to zabbix.

```chown -R zabbix:zabbix /usr/lib/zabbix/alertscripts```

5. Create your media type in Zabbix and point it at the  script as below;
- Name: `thinQ SMS`
- Type: `Script`
- Script name: `thinq-alert.sh`
- Script parameters:
	- `-c/usr/lib/zabbix/alertscripts/thinq-alert.conf`
	- `{ALERT.MESSAGE}`
	- `Enabled: True`

6. Create an action that uses your new media type named `thinQ SMS`.

7. Create an escalation media type and assign it to the ``twilio-alert-escalate.sh`` script. [optional]

8. Create a cronjob to run ``twilio-alert-notify.sh``  [optional]

_Note: If you edit these files in windows you may be adding windows "returns" to the ends of the lines.

Windows defines a new line with "\r\n" unix systems just use "\n". This is easily remidied with:_

```

tr -d '\r' < infile > outfile

```
