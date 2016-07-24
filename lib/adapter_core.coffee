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


# core of advanced API adapter
# detering which adapter to load
# pass the request if function exists and user allowed to do so

fs = require 'fs'
Promise = require 'bluebird'
adapters_path = __dirname+'/advanced_adapter/adapter-'

#list of advanced commands: with elevated permissions
advanced_commands = []

#adapter core class: giving shared api for all adapters+ error handling
class AdapterCore
  constructor: (robot) ->
    @robot = robot
    # try to load specific adapter, if not: make it empty
    try
      fs.accessSync(adapters_path+@robot.adapterName+'.coffee', fs.F_OK)
      @adapter = new (require adapters_path+@robot.adapterName)()
    catch error
      @adapter = {}
  # PLACEHOLDER: check command if its approved for this user
  approve_command: (command, user_info) ->
    return true

  # exec API command:
  # msg: message object hubot
  # command: command name from list of commands
  # params: params for the specific command
  # example (use with bluebird library):
  # return robot.enterprse.adapter.exec(msg, 'listChannels', param, param)
  # .then (r) ->
  #   ...some code...
  #   return robot.enterprse.adapter.exec(msg, 'join', param)
  # .then (r) ->
  #   .. some other code ..
  # .catch (e) ->
  #   ... some error handling code...
  exec: (msg, command, params...) ->
    # this is not binding inside callbacks
    _this = @
    _robot = @robot
    _adapter = @adapter
    return new Promise (resolve, reject)->
      _robot.logger.debug "Adapter CORE: request to exec #{command} with "+
        "params: ", params
      # reject promise  if no adapter (can be cougnt using .catch function)
      if not _adapter[command]
        _robot.logger.debug "command #{command} not available for adapter "+
          _robot.adapterName
        return reject("command #{command} not available for adapter "+
          _robot.adapterName)
      #TODO: extract user_info probably from Auth module
      user_info = {}
      # reject promise if user have no right to make this call
      if not _this.approve_command user_info, command
        _robot.logger.debug "command #{command} not approved for user"
        reject("command #{command} not approved for user")
      else
        # resolve if all ok, use .apply to expand arr of params to function
        resolve(_adapter[command].apply(_adapter, params))

module.exports = AdapterCore
