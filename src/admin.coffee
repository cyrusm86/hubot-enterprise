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


Promise = require 'bluebird'

module.exports = (robot) ->
  archive = new (require '../lib/archive')(robot.adapterName)

  robot.respond /admin archive older ([0-9]+)([hHmMsS])/i, (msg) ->
    room = msg.message.room;
    seconds = switch
      when msg.match[2]=='h' then msg.match[1]*3600
      when msg.match[2]=='m' then msg.match[1]*60
      when msg.match[2]=='s' then msg.match[1]
    # currently hardcoded patterns
    patterns = ['advantage', 'incident']
    msg.reply 'archiving rooms with pattern: '+patterns+' older than '+msg.match[1]+msg.match[2]
    archive.archive_old(robot, msg, seconds, patterns, room)
      .then (r) ->
        robot.logger.debug 'back from Promise', r
        msg.reply 'done'
