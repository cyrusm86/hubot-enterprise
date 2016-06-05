# hubot-admin

A hubot script for ChatOps Administration integration

## Installation

In hubot project repo, run:

`npm install hubot-admin --save`

Then add **hubot-admin** to your `external-scripts.json`:

```json
[
  "hubot-admin"
]
```

## configuration
 - Slack Web API Token as `SLACK_APP_TOKEN` environment variable

### Slack Web API token generation:
#### for testing:
- Go to https://api.slack.com/docs/oauth-test-tokens
- Generate token from the team the bot should run

#### for production:
- Register new application with slack (make it private) https://api.slack.com/apps
- Add the app to your team to get API token

Run with the generated token as environment variable `SLACK_APP_TOKEN`

## Commands support

Supported commands:

1. archive old: archiving all channels older than specified time
  * `admin archive older 3<h/m/s>`
2. archive specific: archiving specific channel
  * `admin archive channel #channelName`
