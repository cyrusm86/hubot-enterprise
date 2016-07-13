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

path = require('path')
Insight = require('insight')
console.log "DN: ", __dirname
pkg = require('../package.json')
insight = new Insight(
  trackingCode: 'UA-80724671-1'
  pkg: pkg)

insight.optOut = process.env.HUBOT_HE_OPT_OUT || false
insight.track 'HE', 'start'

module.exports = (robot) ->
  robot.enterprise = {}
  robot.enterprise.help = []

  # register a listener function with hubot-enterprise
  #
  # info: list of the function info:
  #  product: product name- OPTIONAL (lib will determin product by itself)
  #  action: action to prerform
  #  type: hear/respond
  #  extra: extra regex (after the first 2), default: " (.*)"
  #  help: help string
  # callback: function to run
  #
  # will register function with the following regex:
  # /#{info.product} #{info.action} (.*)/i


  find_integration_name = ->
    myError = new Error
    trace = myError.stack.split('\n')
    trace.shift()
    filename = __filename.replace(/[A-Z]:\\/, '').replace(/\\/ig, '/')
    fname = ''
    loop
      shift = trace.shift().replace(/[A-Z]:\\/, '').replace(/\\/ig, '/')
      fname = /\((.*):/i.exec(shift)[1].split(':')[0]
      unless fname == filename
        break
    fname.match(/\/hubot-(.*?)\//ig).pop().replace(/hubot-|\//g, '')

  robot.enterprise.create = (info, callback) ->
    integration_name = find_integration_name()
    info.product = info.product || integration_name
    extra = info.extra||"(.*)"
    if !info.type || (info.type != 'hear')
      info.type = 'respond'
    robot.enterprise.help.push(info)
    re = new RegExp("#{info.product} #{info.action} #{extra}", 'i')
    robot[info.type] re, (msg) ->
      callback(msg, robot)

  # return enterprise help to string
  robot.enterprise.show_help = (product) ->
    res = ""
    for elem in robot.enterprise.help
      if !product || elem.product == product.trim()
        res+="\n"+(if elem.type == "respond" then "@#{robot.name} " else "" )+
        "#{elem.product} #{elem.action}: #{elem.help}"
    if !res
      product = if product then product.trim() else ""
      res = "\nthere is no such integration #{product}"
    res = "enterprise help"+res
    return res

  # listener for help message
  robot.respond /enterprise(.*)/i, (msg) ->
    msg.reply robot.enterprise.show_help(msg.match[1])
