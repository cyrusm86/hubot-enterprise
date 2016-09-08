# Notes:
#  Copyright 2016 Hewlett-Packard Development Company, L.P.
#
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copie of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#  SOFTWARE.

# Bootstraping hubot-enterprise
# adding enterprise functions to robot object
Path = require('path')
Insight = require('insight')
_ = require 'lodash'
pkg = require('../package.json')

Adapter =
insight = new Insight(
  trackingCode: process.env.HUBOT_HE_GA_CODE || 'UA-80724671-1'
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

  # build extra part of the regex
  #
  # info: info object from build_enterprise_regex
  #  extra: extra element
  #    optional: true/false- should it be optional
  #    re: string that representing the regex (optional)
  build_extra_re = (info) ->
    # default values set for backward compatibility
    if (typeof info.extra == "string" && !info.regex_suffix)
      info.regex_suffix = {re: info.extra, optional: false}
    # init extra if its not there
    info.regex_suffix = info.regex_suffix || {optional: true, re: undefined}
    extra = info.regex_suffix
    if (typeof extra != "object")
      throw new Error("info.regex_suffix MUST be an object")
    # check that re is string or undefined
    if ! _.includes(["undefined", "string"], (typeof extra.re))
      throw new Error("Cannot register a listener, info.regex_suffix.re must "+
        "be a string or undefined")
    # check that optional is boolean or undefined
    if ! _.includes(["undefined", "boolean"], (typeof extra.optional))
      throw new Error("Cannot register a listener, info.regex_suffix.optional "+
      "must be a boolean or undefined")
    # TODO: prevent calls similarity as much as possible
    # TODO: only one verb+entity may have optional: true
    # TODO: forbid {optional: true} with {re: null, optional: false}
    # TODO: try to check that 2 regexps are not equal (at least no the same)
    if extra.re
      # if extra.re passed and its optional
      if extra.optional
        return "(?: #{extra.re})?"
      #if it's not optional
      else
        return " #{extra.re}"
    #if no extra.re and optional
    else if extra.optional
      return '[ ]?(.*)?'
    #if no extra.re and not optional
    else
      return ''

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
  build_enterprise_regex = (info, integration_name) ->
    # backward compatibility for old version (verb vas called action)
    if info.action
      info.verb = info.action
      delete info.action
    info.product = info.product || integration_name
    if !info.verb
      throw new Error("Cannot register listener for #{info.product}, "+
        "no verb passed")
    if info.verb.includes(" ") || (info.entity && info.entity.includes(" "))
      throw new Error("Cannot register listener for #{info.product}, "+
        "verb/entity must be a single word")
    info.regex = build_extra_re(info)
    if !info.type || (info.type != 'hear')
      info.type = 'respond'
    re_string = "#{info.product} #{info.verb}"
    if info.entity
      re_string += " #{info.entity}"
    re_string+= "#{info.regex}$"
    robot.e.help.push(info)
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
  # options: An Object of additional parameters keyed on extension name
  #          (optional) as described in:
  #          https://hubot.github.com/docs/scripting/#listener-metadata
  # callback: function to run
  #
  # will register function with the following regex:
  # robot[info.type]
  #  /#{info.product} #{info.verb} #{info.entity} #{info.extra}/i
  robot.e.create = (info, args...) ->
    if !args.length
      throw new Error('please pass a callback')
    # set callback and options using arguments array
    callback = if args.length > 1 then args[1] else args[0]
    options = if args.length > 1 then args[0] else {}
    if typeof callback != 'function'
      throw new Error('callback is not a function but a '+(typeof callback))
    re = build_enterprise_regex(info, find_integration_name())
    robot.logger.debug("HE registering call:\n"+
      "\trobot.#{info.type} #{re.toString()},", options)
    robot[info.type] re, options, (msg) ->
      callback(msg, robot)

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

  # listener for help message
  robot.respond /enterprise(.*)/i, (msg) ->
    msg.reply robot.e.show_help(msg.match[1])

  # robot.enterprise as alias to robot.e for backward compatibility
  robot.enterprise = robot.e

  # load hubot enterprise scripts (not from integrations) after HE loaded
  load_he_scripts('enterprise_scripts')
