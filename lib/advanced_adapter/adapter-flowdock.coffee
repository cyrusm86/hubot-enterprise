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


# admin actions for flowdock

request = require 'request'
Promise = require 'bluebird'
Channel = require './libs/channel'
Querystring = require 'querystring'
_ = require 'lodash'
class Adapter
  constructor: (apiToken = process.env.HUBOT_FLOWDOCK_API_TOKEN) ->
    @apiToken = apiToken

  # multiline quotation method for platform
  quote:
    start: "\n```\n"
    end: '```'

  callAPI: (command, type, options) ->
    api_url = "https://#{@apiToken}@api.flowdock.com/"
    options = options||{}
    new Promise (resolve, reject)->
      request[type](api_url + command, form: options,
      (err, reponse, body)->
        if not err and reponse.statusCode == 200
          json = JSON.parse(body)
          reject(json.message) unless !json.message
          resolve(json)
        else
          reject(err)
      )

  # channel info
  channelInfo: (channelId) ->
    return @callAPI('flows/find', 'get', {id: channelId})
    .then (r) ->
      return new Channel(r.id, r.parameterized_name, r.name,
        r.sources[0].created_at, r.description)

  # list all channels
  channelList: (excludeArchived) ->
    _this = @
    return @callAPI('flows', 'get')
    .then (r) ->
      return Promise.map(r, (channel) ->
        return _this.channelInfo(channel.id)
        .then (r) ->
          return r
      )
      .then (r) ->
        return r


  # get list of users
  usersList: () ->
    return @callAPI('users', 'get')
    .then (r) ->
      return r

  findChannels: (channels) ->
    res = []
    if (typeof channels == 'string')
      channels = [channels]
    return @channelList()
    .then (r) ->
      for channel in r
        if (_.includes(channels, channel.name))
          channels.splice(channels.indexOf(channel.name), 1)
        else if (_.includes(channels, channel.parameterized_name))
          channels.splice(channels.indexOf(channel.parameterized_name), 1)
        else
          continue
        res.push(channel.id)
      return res

  # find user/s, return id array
  # users = array of users or string: accepting nick, email, id
  findUsersID: (users) ->
    res = []
    if (typeof users == 'string')
      users = [users]
    return @usersList()
    .then (r) ->
      for user in r
        if (_.includes(users, user.nick))
          users.splice(users.indexOf(user.nick), 1)
        else if (_.includes(users, user.email))
          users.splice(users.indexOf(user.email), 1)
        else if (_.includes(users, user.id))
          users.splice(users.indexOf(user.id), 1)
        else
          continue
        res.push(user.id)
      return res


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
  #   room: room name, id, DM id, username with @ prefix
  #   user: username
  # reply: true/false: prefix message with @#{opt.user}
  customMessage: (robot, msg, message, opt, reply) ->
    _this = @
    if (typeof message == 'string')
      toSend = message
    else
      toSend = []
      if message.title
        toSend.push(message.title)
      if message.text
        toSend.push(message.text)
      if message.link
        if message.link_desc
          toSend.push(message.link_desc+": "+message.link)
        else
          toSend.push(message.link)
      if message.footer
        toSend.push(message.footer)
      toSend = toSend.join('\n')
    if (reply && !opt.custom_msg)
      return msg.respond(toSend)
    # sending the message
    if (reply && (opt.user && opt.room[0] !='@'))
      userText = if (opt.user[0] != '@') then '@'+opt.user else opt.user
      toSend = userText+", "+toSend
    if opt.room[0] == '#'
      # resolve channel name to id
      new Promise (resolve, reject) ->
        return _this.findChannels(opt.room.replace('#', ''))
        .then (r) ->
          resolve(robot.send {room: r[0]}, toSend)
    if opt.room[0] == '@'
      # resolve room user name to id
      new Promise (resolve, reject) ->
        return _this.findUsersID(opt.room.replace('@', ''))
        .then (r) ->
          resolve(robot.send {user: {id: r[0]}}, toSend)

module.exports = Adapter
