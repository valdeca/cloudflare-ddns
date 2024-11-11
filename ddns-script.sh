#!/bin/bash

# Cloudflare and Notification Configuration
auth_email=""                               
auth_method="token"                         
auth_key=""                                 
zone_identifier=""                          
record_name=""                              
ttl=3600                                    
proxy="false"                               
sitename=""                                 
slackchannel=""                             
slackuri=""                                 
discorduri=""                               

# Regular expression for IPv4
ipv4_regex='([0-9]{1,3}\.){3}[0-9]{1,3}'

# Function to retrieve public IP address
get_public_ip() {
  local ip
  ip=$(curl -s -4 https://cloudflare.com/cdn-cgi/trace | grep -oP 'ip=\K'$ipv4_regex'') || \
    ip=$(curl -s https://api.ipify.org || curl -s https://ipv4.icanhazip.com)
  if [[ ! $ip =~ ^$ipv4_regex$ ]]; then
    logger -s "DDNS Updater: Failed to find a valid IP."
    exit 2
  fi
  echo "$ip"
}

# Validate required environment variables
validate_env() {
  if [[ -z "$auth_email" || -z "$auth_key" || -z "$zone_identifier" || -z "$record_name" ]]; then
    logger -s "DDNS Updater: Missing required environment variable(s)."
    exit 1
  fi
}

# Function to set auth header
set_auth_header() {
  if [[ "$auth_method" == "global" ]]; then
    echo "X-Auth-Key: $auth_key"
  else
    echo "Authorization: Bearer $auth_key"
  fi
}

# Function to send notification
send_notification() {
  local message="$1"
  if [[ -n "$slackuri" ]]; then
    curl -s -X POST "$slackuri" --data-raw "{\"channel\": \"$slackchannel\", \"text\": \"$message\"}"
  fi
  if [[ -n "$discorduri" ]]; then
    curl -s -X POST "$discorduri" --data-raw "{\"content\": \"$message\"}"
  fi
}

# Main script execution
validate_env
auth_header=$(set_auth_header)
ip=$(get_public_ip)

logger "DDNS Updater: Check Initiated for $record_name"

# Retrieve A record from Cloudflare
record=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=A&name=$record_name" \
    -H "X-Auth-Email: $auth_email" \
    -H "$auth_header" \
    -H "Content-Type: application/json")

if [[ $record == *"\"count\":0"* ]]; then
  logger -s "DDNS Updater: Record does not exist. (${ip} for ${record_name})"
  exit 1
fi

# Get the current IP from the record
old_ip=$(echo "$record" | jq -r '.result[0].content')
record_identifier=$(echo "$record" | jq -r '.result[0].id')

if [[ $ip == "$old_ip" ]]; then
  logger "DDNS Updater: IP ($ip) for $record_name has not changed."
  exit 0
fi

# Update the Cloudflare record
update=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
    -H "X-Auth-Email: $auth_email" \
    -H "$auth_header" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip\",\"ttl\":$ttl,\"proxied\":${proxy}}")

if [[ $update == *"\"success\":true"* ]]; then
  logger "DDNS Updater: Successfully updated $record_name to $ip."
  send_notification "$sitename Updated: $record_name's new IP Address is $ip"
else
  logger -s "DDNS Updater: Failed to update $record_name ($ip)."
  send_notification "$sitename DDNS Update Failed: $record_name ($ip)"
  exit 1
fi