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

  it 'register respond function', ->
    @room.user.say('alice', '@hubot test update').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot test update' ],
        [ 'hubot', '@alice in test update' ]
      ]
  it 'register hear function', ->
    @room.user.say('alice', 'test read jj').then =>
      expect(@room.messages).to.eql [
        [ 'alice', 'test read jj' ],
        [ 'hubot', '@alice in test read' ]
      ]

  it 'register default project naming', ->
    @room.robot.enterprise.create {action: 'read',
    help: 'read ticket', type: 'hear'}, (msg, _robot)->
      msg.reply 'in enterprise read'
    @room.user.say('alice', 'enterprise read jj').then =>
      expect(@room.messages).to.eql [
        [ 'alice', 'enterprise read jj' ],
        [ 'hubot', '@alice in enterprise read' ]
      ]

  it 'register default listener option (respond)', ->
    @room.robot.enterprise.create {product: 'bar', action: 'read',
    help: 'read ticket'}, (msg, _robot)->
      msg.reply 'in foo read'
    @room.user.say('alice', '@hubot bar read jj').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot bar read jj' ],
        [ 'hubot', '@alice in foo read' ]
      ]

  it 'help general', ->
    @room.user.say('alice', '@hubot enterprise').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot enterprise' ],
        [ 'hubot', '@alice help for hubot enterprise:\n'+
        '@hubot test update: update ticket\n'+
        'test read: read ticket\n'+
        '@hubot foo read: read ticket' ]
      ]

  it 'help specific', ->
    @room.user.say('alice', '@hubot enterprise foo').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot enterprise foo' ],
        [ 'hubot', '@alice help for hubot enterprise:\n'+
        '@hubot foo read: read ticket' ]
      ]

  it 'help none existing', ->
    @room.user.say('alice', '@hubot enterprise bar').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot enterprise bar' ],
        [ 'hubot', '@alice help for hubot enterprise:\n'+
        'there is no such integration bar' ]
      ]
