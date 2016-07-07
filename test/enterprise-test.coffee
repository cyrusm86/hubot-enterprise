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

helper = new Helper('../src/0_bootstrap.coffee')

describe 'enterprise tests', ->
  beforeEach ->
    @room = helper.createRoom()
    @room.robot.enterprise.create {product: 'test', action: 'update',
    help: 'update ticket', type: 'respond'}, (msg, _robot)->
      msg.reply 'in test update'
    @room.robot.enterprise.create {product: 'test', action: 'read',
    help: 'read ticket', type: 'hear'}, (msg, _robot)->
      msg.reply 'in test read'
    @room.robot.enterprise.create {product: 'foo', action: 'read',
    help: 'read ticket', type: 'respond'}, (msg, _robot)->
      msg.reply 'in foo read'
  afterEach ->
    @room.destroy()

  it 'test respond function', ->
    @room.user.say('alice', '@hubot test update jj').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot test update jj' ],
        [ 'hubot', '@alice in test update' ]
      ]
  it 'test hear function', ->
    @room.user.say('alice', 'test read jj').then =>
      expect(@room.messages).to.eql [
        [ 'alice', 'test read jj' ],
        [ 'hubot', '@alice in test read' ]
      ]

  it 'test help general', ->
    @room.user.say('alice', '@hubot enterprise').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot enterprise' ],
        [ 'hubot', '@alice enterprise help\n'+
        '@hubot test update: update ticket\n'+
        'test read: read ticket\n'+
        '@hubot foo read: read ticket' ]
      ]

  it 'test help specific', ->
    @room.user.say('alice', '@hubot enterprise foo').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot enterprise foo' ],
        [ 'hubot', '@alice enterprise help\n'+
        '@hubot foo read: read ticket' ]
      ]

  it 'test help none existing', ->
    @room.user.say('alice', '@hubot enterprise bar').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot enterprise bar' ],
        [ 'hubot', '@alice enterprise help\n'+
        'there is no such integration bar' ]
      ]
