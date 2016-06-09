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

# change log level to eliminate hubot warning about copoyright style
process.env.HUBOT_LOG_LEVEL='error'

Helper = require('hubot-test-helper')
chai = require 'chai'

expect = chai.expect

helper = new Helper('../src/admin.coffee')

describe 'hubot-admin tests', ->
  beforeEach ->
    @room = helper.createRoom()

  afterEach ->
    @room.destroy()

  it 'admin archive #general channel', ->
    @room.user.say('alice', '@hubot admin archive channel #general').then =>
      expect(@room.messages).to.eql [
        ['alice', '@hubot admin archive channel #general']
        ['hubot', '@alice cannot archive #general channel']
      ]

  it 'admin archive #some channel', ->
    @room.user.say('bob', '@hubot admin archive channel #some').then =>
      expect(@room.messages).to.eql [
        ['bob', '@hubot admin archive channel #some']
        ['hubot', '@bob could not find channel some']
      ]
