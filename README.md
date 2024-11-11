# DDNS Updater Script

A bash script to automatically update a DNS A record on Cloudflare with your current public IP address. The script is designed to be used as a Dynamic DNS (DDNS) updater, allowing you to maintain an up-to-date DNS record with your IP address, even when it changes.


## instalation

```bash
git clone https://github.com/xabi-dev/cloudflare-ddns.git
```

## Features
- Retrieves public IPv4 address and updates the Cloudflare DNS record if it changes.
- Supports notifications via Slack and Discord on successful or failed updates.
- Provides logging to track the status of updates.

## Prerequisites
- **Cloudflare Account**: You need an account on Cloudflare with an API token or global API key.
- **Slack/Discord Webhooks (Optional)**: For notifications, set up incoming webhooks on Slack or Discord.

## Setup

### Environment Variables
The following environment variables must be set in the script:

| Variable          | Description                                                       |
| ----------------- | ----------------------------------------------------------------- |
| `auth_email`      | Email address associated with your Cloudflare account             |
| `auth_method`     | Authentication method: `global` for global API key, `token` for scoped API token |
| `auth_key`        | API token or global API key                                       |
| `zone_identifier` | Zone ID for your domain on Cloudflare                             |
| `record_name`     | DNS record to be updated (e.g., `example.com` or `sub.example.com`) |
| `ttl`             | DNS Time-To-Live (TTL) in seconds (e.g., 3600)                    |
| `proxy`           | Set to `"true"` to enable Cloudflare proxy, `"false"` otherwise   |
| `sitename`        | Name of the site, used in notifications                           |
| `slackchannel`    | Slack channel (e.g., `#example`)                                  |
| `slackuri`        | Slack Webhook URL for notifications                               |
| `discorduri`      | Discord Webhook URL for notifications                             |

### Example Configuration
Edit the script to fill in the required variables:

```bash
auth_email="your_email@example.com"
auth_method="token"
auth_key="your_api_key"
zone_identifier="your_zone_id"
record_name="example.com"
ttl=3600
proxy="false"
sitename="Example Site"
slackchannel="#notifications"
slackuri="https://hooks.slack.com/services/your_slack_webhook"
discorduri="https://discordapp.com/api/webhooks/your_discord_webhook"
```
##	1.	Make the script executable:
```bash 
chmod +x ddns-script.sh
```
##	2.	Run the script manually:
```bash 
./ddns-script.sh
```
##	To run the script periodically, add a cron job. For example, to run every 5 minutes:
```bash 
*/5 * * * * /path/to/ddns-script.sh >> /path/to/logfile.log 2>&1
```