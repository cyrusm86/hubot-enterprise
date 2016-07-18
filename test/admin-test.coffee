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

helper = new Helper('../src')

describe 'hubot-admin tests', ->
  beforeEach ->
    @room = helper.createRoom()

  afterEach ->
    @room.destroy()

  it 'admin archive older 5s', ->
    @room.user.say('alice', '@hubot admin archive older 5s').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot admin archive older 5s' ],
        [ 'hubot', '@alice archiving channels with pattern: "advantage", '+
          '"incident" older than 5s by name' ],
        ['hubot', '@alice Error: command channelList not available for '+
          'adapter null']
      ]

  it 'admin archive older 5s named JJ or BB or DDDD', ->
    @room.user.say('alice', '@hubot admin archive older 5s named JJ or BB or '+
    'DDDD').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot admin archive older 5s topic JJ or BB or DDDD' ],
        [ 'hubot', '@alice Channel prefix "JJ" is too short, should be at '+
          'least 3 characters long' ],
        [ 'hubot', '@alice Channel prefix "BB" is too short, should be at '+
          'least 3 characters long' ],
        [ 'hubot', '@alice archiving channels with pattern: "DDDD" older '+
          'than 5s by name' ]
      ]

    it 'admin archive older 5s topic JJ or BB or DDDD', ->
      @room.user.say('alice', '@hubot admin archive older 5s topic BBBB'+
      ' or DDDD').then =>
        expect(@room.messages).to.eql [
          [ 'alice', '@hubot admin archive older 5s topic BBBB or DDDD' ],
          [ 'hubot', '@alice archiving channels with pattern: "BBBB", "DDDD" '+
            'older than 5s by topic' ]
        ]

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
        ['hubot', '@bob could not find channel #some']
      ]
