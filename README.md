# hubot-enterprise

Hubot middleware and scripts for enterprise

This hubot plugins package created to allow quickly enable multiplatform hubot plugins development and deployment with built in 
security flows, help mechanism, standartized user experience in terms of syntax, message templating and collaboration platforms management API adapters.

For more information, please reference our [wiki](https://github.com/eedevops/hubot-enterprise/wiki)

## Quick links for README
- [Installation](#installation)
  - [Docker](#running-hubot-enterprise-via-docker)
  - [Other installation methods](https://github.com/eedevops/hubot-enterprise/wiki/bootstrap)
- [Bot Configuration](#bot-configuration-slack)
  - [for testing](#for-testing)
  - [for production](https://github.com/eedevops/hubot-enterprise/wiki/slack#app-configuration)
- [Built in commands](#built-in-commands)
- [Developing hubot integration with hubot-enterprise support](#developing-hubot-integration-with-hubot-enterprise-support)
  - [Creating new integration](https://github.com/eedevops/hubot-enterprise/wiki/bootstrap-integration)
  - [Writing integration](https://github.com/eedevops/hubot-enterprise/wiki/api)
  - [Testing your integration](https://github.com/eedevops/hubot-enterprise/wiki/testing)
  - [Using jenkins pipeline docker image](https://github.com/eedevops/hubot-enterprise/wiki/jenkins)
- [DISCLAIMER](#disclaimer)

## Installation

The package can quickly be deployed and installed using docker with the following prerequisites:
- docker- recommended version: 1.12. [install docker](https://docs.docker.com/engine/installation/).

The [docker image](Dockerfile) includes:
  - nodejs 4 image: [node:4](https://hub.docker.com/r/library/node/) docker image.
  - [yoeman](http://yeoman.io/).
  - [coffee-script](http://coffeescript.org/).
  - [generator-hubot-enterprise](https://github.com/eedevops/generator-hubot-enterprise) which is a fork of [genarator-hubot](https://github.com/github/generator-hubot).

### Running Hubot Enterprise via docker
 
- `docker pull chatopshpe/hubot-enterprise`
- if using slack: [set up slack](#slack-web-api-token-generation)
- run docker:
  ```bash
  docker run \
     -p 8080:8080 \
     -v <integrations_on_disk>:/integration \
     -e "NPM_INTEGRATIONS=<integration to install from npm>" \
     -e "http_proxy=${http_proxy}" \
     -e "https_proxy=${https_proxy}" \
     -e "no_proxy=${no_proxy}" \
     -e "ADAPTER=slack" \
     -e "HUBOT_LOG_LEVEL=info" \
     -e "SLACK_APP_TOKEN=xxxxxxxxx" \
     -e "HUBOT_SLACK_TOKEN=xxxxxxxxxxx" \
     chatopshpe/hubot-enterprise
  ```
  - **integrations_on_disk**: hubot integrations that located in the specified folder.

    this folder may **BE** an integration or **CONTAIN** number of integration folders (named with `hubot-` prefix).

    examples:

    - `/opt/myIntegration/`: may be a project and contain `package.json` file and all rest project structure.
    - `/opt/myIntegrations`: may contain number of folders that contains integrations like and prefixed with `hubot-`.

  - **NPM_INTEGRATIONS**: list of hubot integrations to be installed using npm.
  
  - **ADAPTER**: default is `slack`, here can specify any other adapter to be installed via npm and used by hubot.
    - When replacing adapter, Please check and add all environment variable associated to it.
	  -Sample values: `flowdock`, `hipchat`.

 - **HUBOT_LOG_LEVEL**: level for hubot logger, default `info` optional values: `debug`|`info`|`error`
 - Run as daemon by adding `-d` after the `docker run`.

### [Other installation methods](https://github.com/eedevops/hubot-enterprise/wiki/bootstrap)

## Bot Configuration (Slack)
 - Slack Web API Token as `SLACK_APP_TOKEN` environment variable
 - Hubot slack token as `HUBOT_SLACK_TOKEN` environment variable

#### for testing:

*BOT TOKEN (for chat)*
- in slack window, click on your slack team.
- click on `Apps & Integrations`.
- Search for `hubot`.
- Create hubot integration.
- set the token as `HUBOT_SLACK_TOKEN` environment variable.

*API TOKEN (for admin functionality)*
- Go to https://api.slack.com/docs/oauth-test-tokens.
- Generate token from the team, where the bot should run.
- set it as `SLACK_APP_TOKEN` environment variable.

#### for production:

- Follow [set up slack](https://github.com/eedevops/hubot-enterprise/wiki/slack#app-configuration).
- Add the new tokens as environment variables `SLACK_APP_TOKEN` and `HUBOT_SLACK_TOKEN`.

## Built in commands

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

## Developing hubot integration with hubot-enterprise support

Example scripts:

- [example.coffee](example/example.coffee)
- [admin.coffee](src/admin.coffee)

Write your own:
  - [Creating new integration](https://github.com/eedevops/hubot-enterprise/wiki/bootstrap-integration)
  - [Writing integration](https://github.com/eedevops/hubot-enterprise/wiki/api)
  - [Testing your integration](https://github.com/eedevops/hubot-enterprise/wiki/testing)
  - [Using jenkins pipeline docker image](https://github.com/eedevops/hubot-enterprise/wiki/jenkins)

## DISCLAIMER

Currently hubot-enterprise support slack platform, other platforms might be added later on.
