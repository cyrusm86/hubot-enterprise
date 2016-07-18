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
Querystring = require 'querystring'
_ = require 'lodash'
class Adapter
  constructor: (apiToken = process.env.HUBOT_FLOWDOCK_API_TOKEN) ->
    @apiToken = apiToken

  callAPI: (command, type, options) ->
    api_url = "https://#{@apiToken}@api.flowdock.com/"
    options = options||{}
    new Promise (resolve, reject)->
      console.log(api_url + command)
      request[type](api_url + command, form: options,
      (err, reponse, body)->
        if not err and reponse.statusCode == 200
          json = JSON.parse(body)
          reject(json.message) unless !json.message
          resolve(json)
        else
          reject(err)
      )

  channelList: (excludeArchived) ->
    return @callAPI('flows', 'get')
    .then (r) ->
      return r

module.exports = Adapter
