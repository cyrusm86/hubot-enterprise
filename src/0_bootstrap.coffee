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


module.exports = (robot) ->
  robot.enterprise = {}
  robot.enterprise.help = []

  # register a listener function with hubot-enterprise
  #
  # info: list of the function info:
  #  product: product name
  #  action: action to prerform
  #  type: hear/respond
  #  extra: extra regex (after the first 2), default: " (.*)"
  #  help: help string
  # callback: function to run
  #
  # will register function with the following regex:
  # /#{info.product} #{info.action} (.*)/i

  robot.enterprise.create = (info, callback) ->
    robot.logger.debug 'in enterprise.create: ', info
    robot.enterprise.help.push(info)
    extra = info.extra||"(.*)"
    re = new RegExp("#{info.product} #{info.action} #{extra}", 'i')
    robot[info.type] re, (msg) ->
      callback(msg, robot)

  # return enterprise help to string
  robot.enterprise.show_help = () ->
    res = "enterprise help"
    for elem in robot.enterprise.help
      res+="\n"+(if elem.type == "respond" then "@#{robot.name} " else "" )+
      "#{elem.product} #{elem.action}: #{elem.help}"
    return res

  # listener for help message
  robot.respond /enterprise/i, (msg) ->
    msg.reply robot.enterprise.show_help()
