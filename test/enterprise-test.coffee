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


Helper = require('hubot-test-helper')
chai = require 'chai'

expect = chai.expect

helper = new Helper('../src/0_bootstrap.coffee')

describe 'enterprise tests', ->
  beforeEach ->
    @room = helper.createRoom()
    @room.robot.respond {product: 'test', verb: 'update', entity: 'ticket'
    help: 'update ticket'}, (msg, _robot)->
      msg.reply 'in test update ticket'
    @room.robot.hear {product: 'test', verb: 'read', entity: 'issue'
    help: 'read ticket'}, (msg, _robot)->
      msg.reply 'in test read issue'
    @room.robot.respond {product: 'foo', verb: 'read', entity: 'ticket'
    help: 'read ticket'}, (msg, _robot)->
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
    @room.robot.hear {verb: 'read',
    help: 'read ticket'}, (msg, _robot)->
      msg.reply 'in enterprise read'
    @room.user.say('alice', 'enterprise read jj').then =>
      expect(@room.messages).to.eql [
        [ 'alice', 'enterprise read jj' ],
        [ 'hubot', '@alice in enterprise read' ]
      ]

  it 'register default listener option (respond)', ->
    @room.robot.respond {product: 'bar', verb: 'read',
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

  # test for backward compatibility robot.enterprise -> robot.e
  it 'check backward compatibility for robot.enterprise', ->
    @room.robot.respond {product: 'foo2', verb: 'read',
    entity: 'ticket', help: 'read ticket'}, (msg, _robot)->
      msg.reply 'in foo2 read ticket'
    @room.user.say('alice', '@hubot foo2 read ticket').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot foo2 read ticket' ],
        [ 'hubot', '@alice in foo2 read ticket' ]
      ]

  # test backward compatibility for call set {product, action}
  it 'check backward compatibility for {product, action}', ->
    @room.robot.respond {product: 'foo2', action: 'read',
    help: 'read ticket'}, (msg, _robot)->
      msg.reply 'in foo2 read'
    @room.user.say('alice', '@hubot foo2 read').then =>
      expect(@room.messages).to.eql [
        [ 'alice', '@hubot foo2 read' ],
        [ 'hubot', '@alice in foo2 read' ]
      ]
