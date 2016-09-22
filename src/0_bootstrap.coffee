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
reserverd_apps = [ 'info', 'help' ]
module.exports = (robot) ->

  # Registrar object- store all integrations meta and info
  # structure: https://github.com/eedevops/he-design/blob/master/README.md#1-roboteregisterintegrationmetadata-authentication
  # automatically create with admin, admin will NEVER have auth because it's not a real module
  registrar = {apps: {}, mapping: {}}

  # create e (enterprise object on robot)
  robot.e = {}
  # `mount` adapter object
  robot.e.adapter = new (require __dirname+
    '/../lib/adapter_core')(robot)

  # create common strings object
  # TODO: use Cha to display
  commons = {
    no_such_integration: (product) ->
      return "there is no such integration *#{product}*"
    no_such_verb: (product, verb) ->
      return "there is no such verb *#{verb}* for integration *#{product}*"
    no_such_entity: (product, verb, entity) ->
      return "there is no such entity *#{entity}* for verb *#{verb}* "+
        "of *#{product}*"
    help_msg: (content) ->
      return "help for hubot enterprise:\n"+content
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
  #  regex_suffix: extra element
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

  find_alias_by_name = (integration_name) ->
    return _.findKey(registrar.mapping, (o) ->
      return o == integration_name)

  registrar_add_call = (info, integration_name) ->
    mapping_name = find_alias_by_name(integration_name)
    verbs = registrar.apps[integration_name].verbs
    # init verb if not exists
    verbs[info.verb] = verbs[info.verb] || {flat: {}, entities: {}}
    verb = registrar.apps[integration_name].verbs[info.verb]
    # for calls with entity
    if info.entity
      # init entity if not exists
      verb.entities[info.entity] = verb.entities[info.entity] || {}
      # basic check for duplicates
      if verb.entities[info.entity][info.regex]
        throw new Error("Cannot register listener for #{mapping_name}, "+
          "similar one already registred, Info: "+JSON.stringify(info))
      verb.entities[info.entity][info.regex] = info
    else
      # register calls without entity
      # basic check for duplicates
      if verb.flat[info.regex]
        throw new Error("Cannot register listener for #{mapping_name}, "+
          "similar one already registred, Info: "+JSON.stringify(info))
      verb.flat[info.regex] = info
     # console.log('REGISTRAR', JSON.stringify(registrar))

  # build regex for enterprise calls and register to HE help module
  # info: list of the function info:
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
    info.product = find_alias_by_name(integration_name)
    # do not accept unregistered integrations
    if !registrar.apps[integration_name]
      throw new Error("cannot register listener for #{integration_name}, "+
        "integration #{integration_name} not registered, please use "+
        "robot.e.registerIntegration")
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
    registrar_add_call(info, integration_name)
    return new RegExp(re_string, 'i')

  # register integration with hubot-enterprise
  #
  # metadata:
  #  name: (optional) Integration alias (how the chat USER will call it)
  #  short_desc: short description of the integration
  #  long_desc: (optional) long description of the integration
  # authentication:
  #  type: one of the allowed type in auth module, e.g: 'username_password'
  #  options: auth options corresponding to selected auth.type
  robot.e.registerIntegration = (metadata, authentication) ->
    integration_name = find_integration_name()
    if _.includes(reserverd_apps, integration_name)
      throw new Error("integration name cannot have reserved name "+
        integration_name)
    if registrar.apps[integration_name]
      throw new Error("Integration #{integration_name} already registred!")
    if (typeof metadata.name == "string")
      if metadata.name.includes(" ")
        throw new Error("Cannot register integration for #{integration_name}, "+
          "name alias must be a single word")
      else if _.includes(reserverd_apps, metadata.name)
        throw new Error("integration metadata.name cannot have reserved name "+
          metadata.name)
      else
        registrar.mapping[metadata.name] = integration_name
    else if _.includes(Object.keys(metadata), 'name')
      throw new Error("Cannot register integration for #{integration_name}, "+
        "name alias must be a string")
    else
      registrar.mapping[integration_name] = integration_name
    # check input
    if !metadata.short_desc
      throw new Error('at least medatada.short_desc must be specified')
    metadata.long_desc = metadata.long_desc || metadata.short_desc
    # check that auth existing and correct
    # TODO: check the auth type existing in auth Module auth.types enum
    # TODO: check that options corresponds with selected Auth type
    #   in auth.type.options

    if authentication && !authentication.type
      throw new Error('Must provide authentication type!')
    registrar.apps[integration_name] = {
      metadata: metadata,
      auth: authentication || {},
      verbs: {}
    }

  # register a listener function with hubot-enterprise
  #
  # info: list of the function info:
  #  product: product name- OPTIONAL (lib will determin product by itself)
  #  verb: verb to prerform
  #  entity: entity for verb to operate (optional)
  #  type: hear/respond
  #  regex_suffix: (optional) extra element
  #    optional: (optional) true/false- should it be optional
  #    re: (optional) string that representing the regex (optional)
  #  help: help string
  # callback: function to run
  #
  # will register function with the following regex:
  # robot[info.type]
  #  /#{info.product} #{info.verb} #{info.entity} #{info.extra}/i
  robot.e.create = (info, callback) ->
    if typeof callback != 'function'
      throw new Error('callback is not a function but a '+(typeof callback))
    info.cb = callback
    re = build_enterprise_regex(info, find_integration_name())
    robot.logger.debug("HE registering call:\n"+
      "\trobot.#{info.type} #{re.toString()}")
    robot[info.type] re, (msg) ->
      # TODO: add auth check here, use bluebird promises if async needed
      callback(msg, robot)

  # return enterprise help as string
  #
  # product: product (or alias)
  # verb: verb
  # entity: entity
  #
  robot.e.show_help = (product, verb, entity) ->
    # TODO: use Cha to display
    # TODO: refactor based on UI/UX team specs
    res = ""
    if product
      if !registrar.mapping[product] ||
      !registrar.apps[registrar.mapping[product]]
        res = commons.no_such_integration(product)
      else
        reg_product = registrar.apps[registrar.mapping[product]]
        if verb
          if !reg_product.verbs[verb]
            res = commons.no_such_verb(product, verb)
          else
            reg_verb = reg_product.verbs[verb]
            if entity
              if !reg_verb.entities[entity]
                res = commons.no_such_entity(product, verb, entity)
              else
                res = "calls for *#{product} #{verb} #{entity}*\n"
                for k, v of reg_verb.entities[entity]
                  res += "\t- "
                  if v.type == 'respond'
                    res += "#{robot.name} "
                  res +="#{product} #{verb} #{entity}#{k}"+
                  (if v.help then ': '+v.help else '')+"\n"
            else
              res += "calls for *#{product} #{verb}*\n"
              entities = Object.keys(reg_verb.entities)
              flat = Object.keys(reg_verb.flat)
              if entities.length > 0
                res += "- *Entities*: "+entities.join(', ')+"\n"
              if flat.length > 0
                res += "- *Calls: *\n"
                for k, v of reg_verb.flat
                  res += "\t- "
                  if v.type == 'respond'
                    res += "#{robot.name} "
                  res +="#{product} #{verb}#{k}"+
                    (if v.help then ': '+v.help else '')+"\n"
        else
          vrbs = Object.keys(reg_product.verbs).join(', ')
          res += "*#{product}* Integration: "+
            "#{reg_product.metadata.short_desc}\n- *Verbs:* #{vrbs}\n"+
            "- *Description:*\n#{reg_product.metadata.long_desc}\n"
    else
      res += "Enterprise integrations list:\n"
      for alias, app of registrar.mapping
        res += "\t-#{alias}: #{registrar.apps[app].metadata.short_desc}\n"
    res = commons.help_msg(res)
    return res

  # listener for help message
  robot.respond /(enterprise|info)[ ]?(\w+)?[ ]?(\w+)?[ ]?(\w+)?/i, (msg) ->
    msg.reply robot.e.show_help(msg.match[2], msg.match[3], msg.match[4])

  # robot.enterprise as alias to robot.e for backward compatibility
  robot.enterprise = robot.e

  # load hubot enterprise scripts (not from integrations) after HE loaded
  load_he_scripts('enterprise_scripts')
