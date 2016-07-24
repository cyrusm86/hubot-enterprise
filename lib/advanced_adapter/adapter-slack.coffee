###
Copyright 2016 Hewlett-Packard Development Company, L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
Software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
###


# admin actions for Slack

Querystring = require 'querystring'
SlackApi = require './libs/slack_web_api'
Promise = require 'bluebird'
_ = require 'lodash'

# slack adapter
class Adapter
  # constructor
  # apiToken: optional api token, should be in env
  constructor: (apiToken = process.env.SLACK_APP_TOKEN) ->
    @apiToken = apiToken

  # set channel topic
  # channelId: id or name of the channel
  # topic: string for the topic
  setTopic: (channelId, topic)->
    opts =
      token: @apiToken
      topic: topic
    return @channelNameToId(channelId)
    .then (r) ->
      opts.channel = r
      return SlackApi.channels.setTopic opts

  # join (self) to channel
  # channelName: channel Name
  join: (channelName) ->
    opts =
      token: @apiToken
      name: channelName
    SlackApi.channels.join opts

  # archive channel
  # channelId: id or name of the channel
  archive: (channelId) ->
    opts = {token: @apiToken}
    return @channelNameToId(channelId)
    .then (r) ->
      opts.channel = r
      return SlackApi.channels.archive opts

  # rename channel
  # channelId: id or name of the channel
  # channelName: new name to channel
  rename: (channelId, channelName) ->
    opts =
      token: @apiToken
      name: channelName
    return @channelNameToId(channelId)
    .then (r) ->
      opts.channel = r
      return SlackApi.channels.rename opts

  # list channels
  # excludeArchived: exclude archived channels
  channelList: (excludeArchived) ->
    opts =
      token: @apiToken
      exclude_archived: excludeArchived
    return SlackApi.channels.list(opts)
    .then (r) ->
      return r.channels

  # get info for specific channel
  # channelId: id or name of the channel
  channelInfo: (channelId) ->
    opts = {token: @apiToken}
    return @channelNameToId(channelId)
    .then (r) ->
      opts.channel = r
      return SlackApi.channels.info(opts)
    .then (r) ->
      return r.channel

  # get channel name or id, if prefixed with # try to translate to channel ID
  # if not: return as is (assuming its channel ID)
  channelNameToId: (channel) ->
    if not channel.startsWith('#')
      # return resolved promise with channel ID
      return Promise.resolve(channel)
    # assume channel name and try to resolve
    return @getChannelID(channel)

  # get channel NAME and translating to ID
  getChannelID: (channel) ->
    # return promise that resolving the channel name to channel ID
    _this = @
    return new Promise (resolve, reject) ->
      return _this.channelList(true)
      .then (r) ->
        for ch in r
          if ch.name == channel.substr(1)
            console.log("#{channel} is #{ch.id}")
            return resolve(ch.id)
        return reject("could not find channel #{channel}")



module.exports = Adapter
