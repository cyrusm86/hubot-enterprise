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


#AdminExt = require './admin-slack'
Promise = require 'bluebird'
moment = require 'moment'
ARCH_PREFIX = 'ARCH-'
#adapter = new AdminExt()

class Archive
  constructor: (robot) ->
    @adapter = robot.enterprise.adapter
    @robot = robot

  sort_channels: (msg, channels, current, regex, type) ->
    ret = []
    type = type || 'name'
    for channel in channels
      to_test = if (type == 'name') then channel.name else channel.topic
      if regex.test(to_test) && channel.name!=current
        @robot.logger.debug to_test
        ret.push channel
    return ret

  archive_single: (msg, channel) ->
    _adapter = @adapter
    _robot = @robot
    @robot.logger.debug channel
    @robot.logger.debug 'joining'
    return _adapter.exec(msg, 'join', channel.name)
    .then (r) ->
      _robot.logger.debug 'join: '+r+', -> setTopic'
      return _adapter.exec(msg, 'setTopic', channel.id, channel.name)
      .then (r) ->
        _robot.logger.debug 'setTopic: '+r+' , -> archive'
        return _adapter.exec(msg, 'archive', channel.id)
      .then (r) ->
        _robot.logger.debug 'archive: '+r+', -> rename'
        return _adapter.exec(msg, 'rename', channel.id, ARCH_PREFIX+Date.now())
      .then (r) ->
        _robot.logger.debug 'rename: '+r+', -> BACK'
        msg.reply 'archived channel: '+channel.name+' ('+channel.id+'), '+
            'created '+moment(channel.created*1000).fromNow()
        return channel.name

  archive_channel: (msg, channel) ->
    _adapter = @adapter
    _this = this
    @robot.logger.debug "in archive channel"
    return _adapter.exec(msg, 'channelInfo', channel)
    .then (r) ->
      return _this.archive_single(msg, r)

  archive_old: (msg, seconds, patterns, thisChannel, type) ->
    _this = this
    totalArchived = 0
    _robot = @robot
    type = type || 'name'
    channelPatterns = new RegExp('('+(patterns.join '|')+')', 'i')
    now = Math.floor(Date.now()/1000)
    _robot.logger.debug 'Archiving older than :'+seconds+' seconds'
    return @adapter.exec(msg, 'channelList', true)
    .then (r) ->
      channels = _this.sort_channels(msg, r, thisChannel, channelPatterns,
        type)
      return Promise.map(channels, (channel) ->
        create_time = now - channel.created
        _robot.logger.debug 'Channel: '+channel.name+' Create elapsed time: '+
          create_time+' created time: '+channel.created
        if create_time > seconds
          _robot.logger.debug 'archiving '+channel.name+' '+channel.id+
            ' ('+create_time+')'
          return _this.archive_single(msg, channel)
          .then (r) ->
            totalArchived++
            return r
      )
      .then (r) ->
        _robot.logger.debug 'MAP DONE'
        r.totalArchived = totalArchived
        return r
      .catch (r) ->
        _robot.logger.debug 'ERROR:'+r
        r.totalArchived = totalArchived
        return r
module.exports = Archive
