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
Channel = require './libs/channel'
Promise = require 'bluebird'
_ = require 'lodash'

# slack adapter
class Adapter
  # constructor
  # apiToken: optional api token, should be in env
  constructor: (apiToken = process.env.SLACK_APP_TOKEN) ->
    @apiToken = apiToken

  # multiline quotation method for platform
  quote:
    start: '```'
    end: '```'

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

  # create DM Channel:
  # using BOT token and no API token
  # user: user ID or @user
  createDM: (user) ->
    _this = @
    opts =
      token: process.env.HUBOT_SLACK_TOKEN
    return new Promise (resolve, reject) ->
      if (user[0] != '@')
        return user
      return _this.findUsersID(user.replace('@', ''))
      .then (r) ->
        opts.user = r[0]
        return SlackApi.im.open opts
      .then (r) ->
        resolve(r.channel.id)

  # join (self) to channel
  # channelName: channel Name
  join: (channelName) ->
    opts =
      token: @apiToken
      name: channelName
    SlackApi.channels.join opts

  # leave (self) from channel
  # channelName: channel Name or id
  leave: (channelName) ->
    opts =
      token: @apiToken
    opts = {token: @apiToken}
    return @channelNameToId(channelName)
    .then (r) ->
      opts.channel = r
      return SlackApi.channels.leave opts

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
    ret = []
    opts =
      token: @apiToken
      exclude_archived: excludeArchived
    return SlackApi.channels.list(opts)
    .then (r) ->
      for channel in r.channels
        ret.push(Channel(channel.id, channel.name, channel.name,
          channel.created, topic.value))
      console.log(ret)
      return ret

  # get info for specific channel
  # channelId: id or name of the channel
  channelInfo: (channelId) ->
    opts = {token: @apiToken}
    return @channelNameToId(channelId)
    .then (r) ->
      opts.channel = r
      return SlackApi.channels.info(opts)
    .then (r) ->
      channel = r.channel
      return new Channel(channel.id, channel.name, channel.name,
        channel.created, topic.value)

  # create and invite to channel
  # channelName: name of the new channel
  # users: string or array of user nick, email, id
  createChannelAndInvite: (channelName, users) ->
    _this = @
    return _this.createChannel(channelName)
    .then (r) ->
      return _this.inviteToChannel('#'+r.name, users)

  # invite users to channel
  # channelName: name of channel
  # users: string or array of user nick, email, id
  inviteToChannel: (channelName, users) ->
    _this = @
    opts =
      token: @apiToken
    userList = []
    return @findUsersID(users)
    .then (r) ->
      userList = r
      return _this.channelNameToId(channelName)
      .then (channel) ->
        opts.channel = channel
        return Promise.map(userList, (user) ->
          opts.user = user
          return SlackApi.channels.invite(opts)
          .catch (e) ->
            if (e == 'cant_invite_self')
              return _this.join(channelName)
            if (e != 'already_in_channel')
              reject(e)
        )

  # remove users from channel
  # channelName: name (prefixed with #) or id of channel
  # users: string or array of user nick, email, id
  removeFromChannel: (channelName, users) ->
    _this = @
    opts =
      token: @apiToken
    userList = []
    return @findUsersID(users)
    .then (r) ->
      userList = r
      return _this.channelNameToId(channelName)
      .then (channel) ->
        opts.channel = channel
        return Promise.map(userList, (user) ->
          opts.user = user
          return SlackApi.channels.kick(opts)
           .catch (e) ->
             if (e == 'cant_kick_self')
               return _this.leave(channel)
        )

  # create new channel by name
  # channelName: name of the new channel
  createChannel: (channelName) ->
   opts =
      token: @apiToken
      name: channelName
    return SlackApi.channels.create(opts)
    .then (r) ->
      return {id: r.channel.id, name: r.channel.name}

  # find user/s, return id array
  # users = array of users or string: accepting nick, email, id
  findUsersID: (users) ->
    res = []
    if (typeof users == 'string')
      users = [users]
    return @usersList()
    .then (r) ->
      for user in r
        # check if username or email or id match to any in the list of users
        # (case sensitive!)
        if (_.includes(users, user.name))
          users.splice(users.indexOf(user.name), 1)
        else if (_.includes(users, user.profile.email))
          users.splice(users.indexOf(user.profile.email), 1)
        else if (_.includes(users, user.id))
          users.splice(users.indexOf(user.id), 1)
        else
          continue;
        res.push(user.id)
      return res

  # get list of users
  usersList: () ->
    opts =
      token: @apiToken
    return SlackApi.users.list(opts)
    .then (r) ->
      return r.members

  # get channel name or id, if prefixed with # try to translate to channel ID
  # if not: return as is (assuming its channel ID)
  channelNameToId: (channel) ->
    if not channel.startsWith('#')
      # return resolved promise with channel ID
      return Promise.resolve(channel)
    # assume channel name and try to resolve
    return @getChannelID(channel)

  # get channel NAME and translating to ID
  # channel: should be prefixed with #
  getChannelID: (channel) ->
    # return promise that resolving the channel name to channel ID
    _this = @
    return new Promise (resolve, reject) ->
      return _this.channelList(true)
      .then (r) ->
        for ch in r
          if ch.name == channel.substr(1)
            return resolve(ch.id)
        return reject("could not find channel #{channel}")

  # custom message function
  # robot: robot object
  # msg: hubot message object
  # message: custom message object or str (for basic)
  #   text: text message
  #   color: hex color representation or 'green/yellow/red'
  #   title: message title
  #   link: url
  #   image: url
  #   footer: string
  #   footer_icon: url
  # opt: opt obj
  #  room: room name, id, DM id, username with @ prefix
  #  user: username
  # reply: true/false: prefix message with @#{opt.user}
  customMessage: (robot, msg, message, opt, reply) ->
    _this = @
    # building message
    if (typeof message == 'string')
      toSend = message
    else
      toSend =
        as_user: false
        username: robot.name
        attachments: [
          {
            color: message.color
            fallback: message.text || ''
            pretext: message.title || ''
            title: message.link_desc || ''
            title_link: message.link || ''
            text: message.text || ''
            image_url: message.image
            footer: message.footer || ''
            footer_icon: message.footer_icon
          }
        ]
    # if reply and the channel is not Direct message or
    # prefixed by @: add @#{msg.user}
    if (reply && (opt.user && !_.includes(['D', '@'], opt.room[0])))
      userText = if (opt.user[0] != '@') then '@'+opt.user else opt.user
      if (typeof toSend == 'string')
        toSend = userText+": "+toSend
      else
        toSend.attachments[0].pretext = userText+": "+
          (toSend.attachments[0].pretext || '')
    # if room starts with @ (user) find the user, open DM channel
    # and send the message there
    if opt.room[0] == '@'
      return new Promise (resolve, reject) ->
        return _this.createDM(opt.room)
        .then (r) ->
          # send to DM channel
          robot.send {room: r}, toSend
    # send to channel (if now DM)
    # robot.send {room: opt.room}, toSend

module.exports = Adapter
