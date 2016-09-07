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


Helper = require('hubot-test-helper')
chai = require 'chai'
extend = require('util')._extend

expect = chai.expect

helper = new Helper('../src/0_bootstrap.coffee')

describe 'basic enterprise tests', ->
  beforeEach ->
    @room = helper.createRoom()
    @room.robot.e.create {product: 'test', verb: 'update', entity: 'ticket'
    help: 'update ticket', type: 'respond'}, (msg)->
      msg.reply 'in test update ticket'
    @room.robot.e.create {product: 'test', verb: 'read', entity: 'issue'
    help: 'read ticket', type: 'hear'}, (msg)->
      msg.reply 'in test read issue'
    @room.robot.e.create {product: 'foo', verb: 'read', entity: 'ticket'
    help: 'read ticket', type: 'respond'}, (msg)->
      msg.reply 'in foo read ticket'
  afterEach ->
    @room.destroy()

  it 'register respond function', ->
    @room.user.say('alice', '@hubot test update ticket').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot test update ticket' ],
        [ 'hubot', '@alice in test update ticket' ]
      ]

  it 'register hear function', ->
    @room.user.say('alice', 'test read issue jj').then =>
      expect(@room.messages).to.eql [
        [ 'alice', 'test read issue jj' ],
        [ 'hubot', '@alice in test read issue' ]
      ]

  it 'register default project naming', ->
    @room.robot.e.create {verb: 'read',
    help: 'read ticket', type: 'hear'}, (msg)->
      msg.reply 'in enterprise read'
    @room.user.say('alice', 'enterprise read jj').then =>
      expect(@room.messages).to.eql [
        [ 'alice', 'enterprise read jj' ],
        [ 'hubot', '@alice in enterprise read' ]
      ]

  it 'register default listener option (respond)', ->
    @room.robot.e.create {product: 'bar', verb: 'read',
    help: 'read ticket'}, (msg)->
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
        '@hubot test update ticket: update ticket\n'+
        'test read issue: read ticket\n'+
        '@hubot foo read ticket: read ticket' ]
      ]

  it 'help specific', ->
    @room.user.say('alice', '@hubot enterprise foo').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot enterprise foo' ],
        [ 'hubot', '@alice help for hubot enterprise:\n'+
        '@hubot foo read ticket: read ticket' ]
      ]

  it 'help none existing', ->
    @room.user.say('alice', '@hubot enterprise bar').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot enterprise bar' ],
        [ 'hubot', '@alice help for hubot enterprise:\n'+
        'there is no such integration bar' ]
      ]

  it 'verb should exist', ->
    err = 'none'
    try
      @room.robot.enterprise.create {product: 'foo2',
      entity: 'ticket', help: 'read ticket', type: 'respond'}, (msg)->
        msg.reply 'in foo2 read ticket'
    catch error
      err = error.message
    expect(err).to.eql('Cannot register listener for foo2, no verb passed')

  it 'verb should not contain spaces', ->
    err = 'none'
    try
      @room.robot.enterprise.create {product: 'foo2', verb: 'with space'
      entity: 'ticket', help: 'read ticket', type: 'respond'}, (msg)->
        msg.reply 'in foo2 read ticket'
    catch error
      err = error.message
    expect(err).to.eql('Cannot register listener for foo2, verb/entity must '+
      'be a single word')

  it 'entity should not contain spaces', ->
    err = 'none'
    try
      @room.robot.enterprise.create {product: 'foo2', verb: 'with'
      entity: 'with space', help: 'read ticket', type: 'respond'}, (msg)->
        msg.reply 'in foo2 read ticket'
    catch error
      err = error.message
    expect(err).to.eql('Cannot register listener for foo2, verb/entity must '+
      'be a single word')

  # test for backward compatibility robot.enterprise -> robot.e
  it 'check backward compatibility for robot.enterprise', ->
    @room.robot.enterprise.create {product: 'foo2', verb: 'read',
    entity: 'ticket', help: 'read ticket', type: 'respond'}, (msg)->
      msg.reply 'in foo2 read ticket'
    @room.user.say('alice', '@hubot foo2 read ticket').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot foo2 read ticket' ],
        [ 'hubot', '@alice in foo2 read ticket' ]
      ]

  # test backward compatibility for call set {product, action}
  it 'check backward compatibility for {product, action}', ->
    @room.robot.e.create {product: 'foo2', action: 'read',
    help: 'read ticket', type: 'respond'}, (msg)->
      msg.reply 'in foo2 read'
    @room.user.say('alice', '@hubot foo2 read').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot foo2 read' ],
        [ 'hubot', '@alice in foo2 read' ]
      ]

describe 'info.extra tests', ->

  callback = (msg) ->
    if msg.match[1]
      msg.reply "#{msg.match[1]}"
    else
      msg.reply "NONE"

  beforeEach ->
    @room = helper.createRoom()

  # common create object, to extend
  common_create = {product: 'foo', verb: 'verb', entity: 'entity'}

  afterEach ->
    @room.destroy()

  it 'extra: regex, optional: true- call with extra', ->
    call = extend({extra: {re: 'with (.*)', optional: true}}, common_create)
    @room.robot.e.create call, callback
    @room.user.say('alice', '@hubot foo verb entity with me').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot foo verb entity with me' ],
        [ 'hubot', '@alice me' ]
      ]

  it 'extra: regex, optional: true- call w/o extra', ->
    call = extend({extra: {re: 'with (.*)', optional: true}}, common_create)
    @room.robot.e.create call, callback
    @room.user.say('alice', '@hubot foo verb entity').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot foo verb entity' ],
        [ 'hubot', '@alice NONE' ]
      ]

  it 'extra, regex, optional: false- call with extra', ->
    call = extend({extra: {re: 'with (.*)', optional: false}}, common_create)
    @room.robot.e.create call, callback
    @room.user.say('alice', '@hubot foo verb entity with me').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot foo verb entity with me' ],
        [ 'hubot', '@alice me' ]
      ]

  it 'extra, regex, optional: false- call without extra', ->
    call = extend({extra: {re: 'with (.*)', optional: false}}, common_create)
    @room.robot.e.create call, callback
    @room.user.say('alice', '@hubot foo verb entity').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot foo verb entity' ]
      ]

  it 'extra, no regex, optional: true- call with extra', ->
    call = extend({extra: {optional: true}}, common_create)
    @room.robot.e.create call, callback
    @room.user.say('alice', '@hubot foo verb entity with me').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot foo verb entity with me' ],
        [ 'hubot', '@alice with me' ]
      ]

  it 'extra, no regex, optional: false- call with extra', ->
    call = extend({extra: {optional: false}}, common_create)
    @room.robot.e.create call, callback
    @room.user.say('alice', '@hubot foo verb entity with me').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot foo verb entity with me' ]
      ]

    it 'extra, no regex, optional: false- call without extra', ->
      call = extend({extra: {optional: false}}, common_create)
      @room.robot.e.create call, callback
      @room.user.say('alice', '@hubot foo verb entity').then =>
        expect(@room.messages).to.eql [
          [ 'alice', '@hubot foo verb entity with me' ],
          [ 'hubot', '@alice NONE' ]
        ]

  it 'no extra boject- call with extra', ->
    @room.robot.e.create common_create, callback
    @room.user.say('alice', '@hubot foo verb entity with me').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot foo verb entity with me' ],
        [ 'hubot', '@alice with me' ]
      ]

  it 'no extra boject- call without extra', ->
    @room.robot.e.create common_create, callback
    @room.user.say('alice', '@hubot foo verb entity').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot foo verb entity' ],
        [ 'hubot', '@alice NONE' ]
      ]

  it 'extra passed as string (backward compatibility)- call with extra', ->
    common_create.extra = "with (.*)"
    @room.robot.e.create common_create, callback
    @room.user.say('alice', '@hubot foo verb entity with me').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot foo verb entity with me' ],
        [ 'hubot', '@alice me' ]
      ]

  it 'extra passed as string (backward compatibility)- call without extra', ->
    common_create.extra = "with (.*)"
    @room.robot.e.create common_create, callback
    @room.user.say('alice', '@hubot foo verb entity').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot foo verb entity' ]
      ]
