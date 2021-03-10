# fail2ban-slack

[Fail2ban](https://www.fail2ban.org/wiki/index.php/Main_Page) Slack action 

### Installation

- Configure Slack [webhook](https://api.slack.com/messaging/webhooks) for fail2ban use
- copy systemd/override.conf to /etc/systemd/system/fail2ban.service.d/ and define environment variables
- copy slack-notify.conf to /etc/fail2ban/action.d/
- restart fail2ban
