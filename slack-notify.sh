#!/usr/bin/env bash

set -euo pipefail

#--------------------------------------------------------------
# FUNCTIONS
#--------------------------------------------------------------

# function: get_county
function get_country () {
  country=$(curl -s -X GET https://ipinfo.io/${1}/country)
  echo "${country}" | tr '[:upper:]' '[:lower:]'
}

# function: usage
function usage () {
  cat << EOF

  Usage: $0 -m message -i ip -u url -c channel

    -m, --message   message to be sent to slack
    -i, --ip        fail2ban <ip> tag
    -u, --url       slack webhook url
    -c, --channel   slack channel name
    -h, --help      shows this help menu

  This script modifies fail2ban action messages with additional information
  like the reporter's hostname and offending ip metadata. IP metadata is 
  queried using fail2ban's <ip> tag. This information along with the original 
  message is concatenated and delivered to the supplied slack webhook url and 
  channel. Slack webhooks can be configured by visiting:

  https://my.slack.com/services/new/incoming-webhook/

EOF
}

#--------------------------------------------------------------
# ARGUEMENTS
#--------------------------------------------------------------

# handle arguements
while getopts ":m:i:c:u:h-:" FLAG; do
  case $FLAG in
    -)
      case ${OPTARG} in
        message)
          message=${OPTARG};
          ;;
        ip)
          ip=${OPTARG};
          ;;
        channel)
          slack_channel=${OPTARG};
          ;;
        url)
          slack_url=${OPTARG};
          ;;
        help)
          usage;
          exit 0;
          ;;
      esac
      ;;
    m)
      message=${OPTARG};
      ;;
    i)
      ip=${OPTARG};
      ;;
    c)
      slack_channel=${OPTARG};
      ;;
    u)
      slack_url=${OPTARG};
      ;;
    h)
      usage;
      exit 0;
      ;;
  esac
done
shift $((OPTIND-1))

#--------------------------------------------------------------
# VARIABLES
#--------------------------------------------------------------

slack_username="fail2ban"
slack_icon=":cop:"
slack_flag=""
host=$(hostname)

#--------------------------------------------------------------
# MAIN
#--------------------------------------------------------------

# get ip metadata
if [ ! -z ${ip+x} ]; then 
  country=$(get_country "${ip}")
  slack_flag=":flag-${country}:"
fi

# message
slack_message="${message/_flag_/$slack_flag}"

# post
curl -s -o /dev/null -X POST \
  --data-urlencode "payload={\"channel\": \"#${slack_channel}\", \"username\": \"${slack_username}\", \"icon_emoji\": \"${slack_icon}\", \"text\": \"[${host}] ${slack_message}\"}" \
  ${slack_url}

# exit
exit 0
