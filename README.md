# hubot-enterprise

Hubot middleware and scripts for enterprise

## Installation

In hubot project repo, run:

`npm install hubot-enterprise --save`

Then add **hubot-enterprise** to your `external-scripts.json`, should
be the **FIRST** in the list:

```json
[
  "hubot-enterprise"
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
  * `admin archive older 3<d/h/m/s>`
    - Default patterns: incident, advantage channel names
  * `admin archive older 3<d/h/m/s> <named|tag> pattern1 or pattern2`:
    - Will archive channels with provided pattern names in channel name or tag
    - Default delimiter is `" or "`, can be changed using env `HUBOT_ADMIN_OR`
    - Default channel min length is `3`, can be changed using env `HUBOT_ADMIN_CHANNEL_MIN`
2. Archive specific: archiving specific channel
  * `admin archive channel #channelName`
  * `admin archive channel this` - to archive current channel
  (_cannot archive private chat or #general channel_)
3. enterprise: show enterprise help
  * `@bot-name: enterprise`

## Using enterprise with integration
Example scripts:

- [example.coffee](example/example.coffee)
- [admin.coffee](src/admin.coffee)

Write your own:
- Start code file as usual hubot script, add this snippet in the head:

```coffee
module.exports = (robot) ->
 if not robot.enterprise
   robot.logger.error 'hubot-enterprise not present, cannot run'
   return
 robot.logger.info 'hubot-test initialized'
```
- To register a listener call the following code:

```coffee
robot.enterprise.create {product: 'test', action: 'create',
help: 'create ticket', type: 'respond|hear'}, (msg, _robot)->
  #your code here

_this = @
@myCallback = (msg, _robot) ->
  #your code here

robot.enterprise.create {product: 'test', action: 'create',
help: 'create ticket', type: 'respond|hear'}, _this.myCallback
```

## Testing integration with enterprise support
**TBD**
