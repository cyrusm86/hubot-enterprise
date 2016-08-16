###
Copyright 2016 Hewlett-Packard Development Company, L.P.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
###


# admin actions for Slack

Querystring = require 'querystring'
SlackApi = require './libs/slack_web_api'
User = require './libs/user'
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
  #
  # channelId: id or name of the channel
  # topic: string for the topic
  #
  # returns true
  # throws Promise rejection
  setTopic: (channelId, topic)->
    opts =
      token: @apiToken
      topic: topic
    return @channelNameToId(channelId)
    .then (r) ->
      opts.channel = r
      return SlackApi.channels.setTopic(opts)
      .then (r) ->
        return true

  # create DM Channel:
  # using BOT token instead of API token
  #
  # user: user ID or @user
  #
  # returns channel id
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
        return SlackApi.im.open(opts)
      .then (r) ->
        resolve(r.channel.id)

  # join (self) to channel
  #
  # channelName: channel Name
  #
  # returns true
  # throws Promise rejection
  join: (channelName) ->
    opts =
      token: @apiToken
      name: channelName
    return SlackApi.channels.join(opts)
    .then (r) ->
      return true

  # leave (self) from channel
  #
  # channelName: channel Name or id
  #
  # returns true
  # throws Promise rejection
  leave: (channelName) ->
    opts = {token: @apiToken}
    return @channelNameToId(channelName)
    .then (r) ->
      opts.channel = r
      return SlackApi.channels.leave(opts)
    .then (r) ->
      return true

  # archive channel
  #
  # channelId: id or name of the channel
  #
  # returns true
  # throws Promise rejection
  archive: (channelId) ->
    opts = {token: @apiToken}
    return @channelNameToId(channelId)
    .then (r) ->
      opts.channel = r
      return SlackApi.channels.archive opts
    .then (r) ->
      return true

  # rename channel
  #
  # channelId: id or name of the channel
  # channelName: new name to channel
  #
  # returns new channel name
  # throws Promise rejection
  rename: (channelId, channelName) ->
    opts =
      token: @apiToken
      name: channelName
    return @channelNameToId(channelId)
    .then (r) ->
      opts.channel = r
      return SlackApi.channels.rename(opts)
    .then (r) ->
      ret.push(new Channel(channel.id, channel.name, channel.name,
        channel.created, ''))

  # list channels
  #
  # excludeArchived: exclude archived channels
  #
  # returns array of Channel objects
  # throws Promise rejection
  channelList: (excludeArchived) ->
    ret = []
    opts =
      token: @apiToken
      exclude_archived: excludeArchived
    return SlackApi.channels.list(opts)
    .then (r) ->
      for channel in r.channels
        ret.push(new Channel(channel.id, channel.name, channel.name,
          channel.created, channel.topic.value))
      return ret

  # get info for specific channel
  #
  # channelId: id or name of the channel
  #
  # returns Channel object
  # throws Promise rejection
  channelInfo: (channelId) ->
    opts = {token: @apiToken}
    return @channelNameToId(channelId)
    .then (r) ->
      opts.channel = r
      return SlackApi.channels.info(opts)
    .then (r) ->
      channel = r.channel
      return new Channel(channel.id, channel.name, channel.name,
        channel.created, channel.topic.value)

  # create and invite to channel
  #
  # channelName: name of the new channel
  # users: string or array of user nick, email, id
  #
  # returns true
  # throws Promise rejection
  createChannelAndInvite: (channelName, users) ->
    _this = @
    return _this.createChannel(channelName)
    .then (r) ->
      return _this.inviteToChannel('#'+r.name, users)
    .then (r) ->
      return true

  # invite users to channel
  #
  # channelName: name of channel
  # users: string or array of user nick, email, id
  #
  # return true
  # throws Promise rejection
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
        .then (r) ->
          return true

  # remove users from channel
  #
  # channelName: name (prefixed with #) or id of channel
  # users: string or array of user nick, email, id
  #
  # returns true
  # throws Promise rejection
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
        .then (r) ->
          return true

  # create new channel by name
  #
  # channelName: name of the new channel
  #
  # returns Channel object
  # throws Promise rejection
  createChannel: (channelName) ->
    opts =
      token: @apiToken
      name: channelName
    return SlackApi.channels.create(opts)
    .then (r) ->
      channel = r.channel
      return new Channel(channel.id, channel.name, channel.name,
        channel.created, channel.topic.value)

  # find channel/s, return id array
  #
  # channels: array of channels or string: accepting name, nice_name, id
  #
  # returns array of user ids
  findChannels: (channels) ->
    res = []
    if (typeof channels == 'string')
      channels = [channels]
    return @channelList()
    .then (r) ->
      for channel in r
        if (_.includes(channels, channel.id))
          channels.splice(channels.indexOf(channel.id), 1)
          res.push(channel.id)
        else if (_.includes(channels, channel.name))
          channels.splice(channels.indexOf(channel.name), 1)
          res.push(channel.id)
        else if (_.includes(channels, channel.nice_name))
          channels.splice(channels.indexOf(channel.nice_name), 1)
          res.push(channel.id)
      return res

  # find user/s, return id array
  #
  # users: array of users or string: accepting nick, email, id
  #
  # returns array of user ids
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
          res.push(user.id)
        else if (_.includes(users, user.email))
          users.splice(users.indexOf(user.email), 1)
          res.push(user.id)
        else if (_.includes(users, user.id))
          users.splice(users.indexOf(user.id), 1)
          res.push(user.id)
      return res

  # get list of users
  #
  # returns array of User objects
  usersList: () ->
    ret = []
    opts =
      token: @apiToken
    return SlackApi.users.list(opts)
    .then (r) ->
      for user in r.members
        ret.push(new User(user.id, user.name, user.profile.email,
          user.profile.first_name, user.profile.last_name))
      return ret

  # get channel name or id, if prefixed with # try to translate to channel ID
  # if not: return as is (assuming its channel ID)
  #
  # channel ID or name (prefixed by #)
  #
  # returns channel id
  channelNameToId: (channel) ->
    if not channel.startsWith('#')
      # returns resolved promise with channel ID
      return Promise.resolve(channel)
    # assume channel name and try to resolve
    return @getChannelID(channel)

  # get channel NAME and translating to ID
  #
  # channel: should be prefixed with #
  #
  # returns channel id
  # throws Promise rejection
  getChannelID: (channel) ->
    # returns promise that resolving the channel name to channel ID
    _this = @
    return new Promise (resolve, reject) ->
      return _this.channelList(true)
      .then (r) ->
        for ch in r
          if ch.name == channel.substr(1)
            return resolve(ch.id)
        return reject("could not find channel #{channel}")

  # custom message function
  #
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
  #
  # returns none
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
    # translate channel with '#'
    if opt.room[0] == '#'
      return new Promise (resolve, reject) ->
        return _this.channelNameToId(opt.room)
        .then (r) ->
          # send to DM channel
          robot.send {room: r}, toSend
    # send to channel (if not DM)
    robot.send {room: opt.room}, toSend

module.exports = Adapter
