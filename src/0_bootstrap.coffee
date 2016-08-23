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

# Bootstraping hubot-enterprise
# adding enterprise functions to robot object
Path = require('path')
Insight = require('insight')
pkg = require('../package.json')
{Listener, TextListener} = require('../../hubot/src/listener')

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

  # build regex for enterprise calls and register to HE help module
  # info: list of the function info:
  #  product: product name- OPTIONAL (lib will determin product by itself)
  #  verb: verb to prerform
  #  entity: entity for verb to operate (optional)
  #  extra: extra regex (after the first 2), default: "[ ]?(.*)?"
  #  type: hear/respond
  #  help: help message for call
  #
  # returns regex:
  #  /#{info.product} #{info.verb} #{info.entity} #{info.extra}/i
  build_enterprise_regex = (info, integration_name, type) ->
    # if plain regex: assume not HE call
    if Object.prototype.toString.call(info) == '[object RegExp]'
      return info
    # backward compatibility for old version (verb vas called action)
    if type
      info.type = type
    if info.action
      info.verb = info.action
      delete info.action
    if !info.verb
      throw new Error("Cannot register function for #{integration_name}, "+
        "no verb passed")
    info.product = info.product || integration_name
    extra = if info.extra then " "+info.extra else "[ ]?(.*)?"
    if !info.type || (info.type != 'hear')
      info.type = 'respond'
    re_string = info.product
    if info.verb
      re_string += " #{info.verb}"
    if info.entity
      re_string += " #{info.entity}"
    re_string+= "#{extra}"
    robot.e.help.push(info)
    robot.logger.debug("HE registering call:\n"+
      "\trobot.#{info.type} /#{re_string}/i")
    return new RegExp(re_string, 'i')

  # register a listener function with hubot-enterprise
  #
  # info: list of the function info:
  #  product: product name- OPTIONAL (lib will determin product by itself)
  #  verb: verb to prerform
  #  entity: entity for verb to operate (optional)
  #  type: hear/respond
  #  extra: extra regex (after the first 2), default: "[ ]?(.*)?"
  #  help: help string
  # callback: function to run
  #
  # will register function with the following regex:
  # robot[info.type] /#{info.product} #{info.verb} #{info.entity} #{info.extra}/i

  # return enterprise help to string
  robot.e.show_help = (product) ->
    res = ""
    for elem in robot.e.help
      if !product || elem.product == product.trim()
        command = elem.product
        if elem.verb
          command += " #{elem.verb}"
        if elem.entity
          command += " #{elem.entity}"
        res += "\n"+(if elem.type == "respond" then "@#{robot.name} " else "" )+
        "#{command}: #{elem.help}"
    if !res
      product = if product then product.trim() else ""
      res = "\n"+robot.e.commons.no_such_integration(product)
    res = robot.e.commons.help_msg(res)
    return res

  # Adds a Listener that attempts to match incoming messages based on
  # a Regex.
  #
  # regex: for non HE use: A Regex that determines if the callback should be called.
  #        for HE use: an object with the following keys:
  #  product: product name- OPTIONAL (lib will determin product by itself)
  #  verb: verb to prerform
  #  entity: entity for verb to operate (optional)
  #  extra: extra regex (after the first 2), default: "[ ]?(.*)?"
  #  help: help string
  #
  #  HE will rebuild the regex to:
  #   robot.hear /#{info.product} #{info.verb} #{info.entity} #{info.extra}/i
  #
  # options  - An Object of additional parameters keyed on extension name
  #            (optional).
  # callback - A Function that is called with a Response object.
  #
  # Returns nothing.
  robot.hear= (regex, options, callback) ->
    toSend = build_enterprise_regex(regex, find_integration_name(), "hear")
    robot.listeners.push new TextListener(robot, toSend, options, callback)

  # Adds a Listener that attempts to match incoming messages directed
  # at the robot based on a Regex. All regexes treat patterns like they begin
  # with a '^'
  #
  # regex: for non HE use: A Regex that determines if the callback should be called.
  #        for HE use: an object with the following keys:
  #  product: product name- OPTIONAL (lib will determin product by itself)
  #  verb: verb to prerform
  #  entity: entity for verb to operate (optional)
  #  extra: extra regex (after the first 2), default: "[ ]?(.*)?"
  #  help: help string
  #
  #
  #  HE will rebuild the regex to:
  #   robot.hear /#{info.product} #{info.verb} #{info.entity} #{info.extra}/i
  #
  # options  - An Object of additional parameters keyed on extension name
  #            (optional).
  # callback - A Function that is called with a Response object.
  #
  robot.respond= (regex, options, callback) ->
    toSend = build_enterprise_regex(regex, find_integration_name(), "respond")
    robot.hear(robot.respondPattern(toSend), options, callback)

  # listener for help message
  robot.respond /enterprise(.*)/i, (msg) ->
    msg.reply robot.e.show_help(msg.match[1])

  # robot.enterprise as alias to robot.e for backward compatibility
  robot.enterprise = robot.e

  # load hubot enterprise scripts (not from integrations) after HE loaded
  load_he_scripts('enterprise_scripts')
