#!/usr/bin/env bash
set -e

# function: usage
function usage () {
  cat <<-EOF

  Usage: $0 -m message -u url -c channel

    -c        slack channel id
    -e        slack icon_emoji
    -m        message
    -U        slack username
    -u        slack webhook url
    -h        shows this help menu

  This script modifies fail2ban action messages with additional information
  like the reporter's hostname and offending ip metadata. IP metadata is 
  queried using fail2ban's <ip> tag. This information along with the original 
  message is concatenated and delivered to the supplied slack webhook url and 
  channel. Slack webhooks can be configured by visiting:

  https://my.slack.com/services/new/incoming-webhook/

EOF
}

# function to_lower
function to_lower () {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# function: get_ipinfo
function get_ipinfo () {
  curl -s -X GET "https://ipinfo.io/$1"
}

# function get_ip_country_flag
function get_ip_country_flag () {
  country=$(get_ipinfo "$1" | jq -r '.country')
  country_lower=$(to_lower "${country}")
  echo ":flag-${country_lower}: [${country}]"
}

# function is_public_ip
function is_public_ip () {
  if echo "$1" | grep -Eq '^(127.0.0.1|192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)'; then
    false
  else
    true
  fi
}

# handle arguements
while getopts ":c:U:e:m:u:h" FLAG; do
  case $FLAG in
    c)
      # channel
      channel=${OPTARG};
      ;;
    U)
      # username
      username=${OPTARG};
      ;;
    e)
      # emoji
      icon_emoji=${OPTARG};
      ;;
    m)
      # message
      message=${OPTARG};
      ;;
    u)
      # url
      url=${OPTARG};
      ;;
    h)
      usage;
      exit 0;
      ;;
    *)
      usage;
      exit 1;
      ;;
  esac
done
shift $((OPTIND-1))


# process message
ip=$(echo "${message}" | grep -Eo '[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+')
if [ -n "${ip}" ] && is_public_ip "${ip}"; then
  flag=$(get_ip_country_flag "${ip}")
  message="${message/$ip/$ip $flag}"
fi

# payload
data=$(jq -n \
  --arg channel "${channel}" \
  --arg username "${username:-fail2ban}" \
  --arg icon_emoji ":${icon_emoji:-cop}:" \
  --arg text "[$(hostname)] ${message}" \
  '{channel: $channel, username: $username, icon_emoji: $icon_emoji, text: $text}')

# post
curl -fsSL -X POST \
  --data-urlencode "payload=${data}" \
  "${url}" \
  -o /dev/null
