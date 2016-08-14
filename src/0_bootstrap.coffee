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

# Bootstraping hubot-enterprise
# adding enterprise functions to robot object
Path = require('path')
Insight = require('insight')
pkg = require('../package.json')

Adapter =
insight = new Insight(
  trackingCode: 'UA-80724671-1'
  pkg: pkg)

insight.optOut = process.env.HUBOT_HE_OPT_OUT || false
insight.track 'HE', 'start'

module.exports = (robot) ->
  # create e (enterprise object on robot)
  robot.e = {}
  # `mount` adapter object
  robot.e.adapter = new (require __dirname+
    '/../lib/adapter_core')(robot)
  # create array for HE integrations to store calls for help
  robot.e.help = []

  # create common strings object
  robot.e.commons = {
    no_such_integration: (product) ->
      return "there is no such integration #{product}"
    help_msg: (content) ->
      return "help for hubot enterprise:"+content
  }

  # load scripts to robot
  load_he_scripts = (path) ->
    scriptsPath = Path.resolve ".", path
    robot.load scriptsPath

  # find integrations names: find by extracting integration name from integration folder
  # hubot-integration will become: `integration`
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
    fmatch = fname.match(/\/hubot-(.*?)\//ig)
    if fmatch
      return fmatch.pop().replace(/hubot-|\//g, '')
    # if not matched- return default 'script'
    return 'script'

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
  robot.e.create = (info, callback) ->
    integration_name = find_integration_name()
    info.product = info.product || integration_name
    extra = if info.extra then " "+info.extra else "[ ]?(.*)?"
    if !info.type || (info.type != 'hear')
      info.type = 'respond'
    robot.e.help.push(info)
    re = new RegExp("#{info.product} #{info.action}#{extra}", 'i')
    robot[info.type] re, (msg) ->
      callback(msg, robot)

  # return enterprise help to string
  robot.e.show_help = (product) ->
    res = ""
    for elem in robot.e.help
      if !product || elem.product == product.trim()
        res+="\n"+(if elem.type == "respond" then "@#{robot.name} " else "" )+
        "#{elem.product} #{elem.action}: #{elem.help}"
    if !res
      product = if product then product.trim() else ""
      res = "\n"+robot.e.commons.no_such_integration(product)
    res = robot.e.commons.help_msg(res)
    return res

  # listener for help message
  robot.respond /enterprise(.*)/i, (msg) ->
    msg.reply robot.e.show_help(msg.match[1])

  # robot.enterprise as alias to robot.e for backward compatibility
  robot.enterprise = robot.e

  # load hubot enterprise scripts (not from integrations) after HE loaded
  load_he_scripts('enterprise_scripts')
