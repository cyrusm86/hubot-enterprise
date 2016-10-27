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

# change log level to eliminate hubot warning about copoyright style

Helper = require 'hubot-test-helper'
chai = require 'chai'
nock = require 'nock'
auth_lib = require '../lib/authentication.coffee'
auth_service = require('he-auth-service')
commons = new (require('../lib/commons.coffee'))()

expect = chai.expect

process.env[auth_lib.env.ENABLE] = 1
auth_service_endpoint = 'https://localhost/'
process.env[auth_lib.env.ENDPOINT] = auth_service_endpoint
helper = new Helper(['../src/0_bootstrap.coffee'])

describe 'Authentication', ->
  metadata =
    short_desc: 'Blah Blah'
    long_desc: 'Blah blah blah blah blah blah blah'
    name: 'mock-auth-integration'

  params = {}

  beforeEach ->
    @room = helper.createRoom()

  afterEach ->
    @room.destroy()
    nock.cleanAll()

  # TODO: test when environment variables are not correctly set

  it 'should specify authentication method via integration registration', ->
    basic_auth = @room.robot.e.auth.generate_basic_auth(params)
    expect(basic_auth).have.keys(['type', 'params'])
    @room.robot.e.registerIntegration(metadata, basic_auth)

  it 'should fail registration when using unsupported authentication' +
      ' method', (done) ->
    method = {
      type: 'unsupported'
    }
    try
      @room.robot.e.registerIntegration(metadata, method)
    catch e
      expect(e).to.exist
      expect(e.toString()).to.equal(
        @room.robot.e.auth.errors.unsupported_type.toString())
      return done()
    done(new Error('did not throw expected exception'))


  it 'should fail registration when not specifying type in the ' +
      'authentication method', (done) ->
    method = {
    }
    try
      @room.robot.e.registerIntegration(metadata, method)
    catch e
      expect(e).to.exist
      expect(e.toString()).to.equal(
        @room.robot.e.auth.errors.no_type.toString())
      return done()
    done(new Error('did not throw expected exception'))

  it 'should load integration without authentication', ->
    @room.robot.e.registerIntegration(metadata, null)

  describe 'BasicAuthentication', ->
    metadata =
      short_desc: 'Basic Auth Example'
      long_desc: 'Showcases how to write an integration ' +
        'that uses BasicAuthentication'
      name: "basic_auth"

    command_params =
      verb: 'get'
      entity: 'something'
      type: 'respond'

    integration_name = 'basic_auth'

    command =
      integration_name + ' ' +
        command_params.verb + ' ' +
        command_params.entity

    user_id = 'pedro'

    should_fail_message = 'Should not run this command, it should fail ' +
      'before internally'

    command_should_not_run = (msg) ->
      msg.reply should_fail_message


    TEST_TIMEOUT = 10000
    ASYNC_MESSAGE_TIMEOUT = 2000

    beforeEach ->
      # register module
      basic_auth = @room.robot.e.auth.generate_basic_auth({})
      @room.robot.e.registerIntegration(metadata, basic_auth)

    it 'should perform integration command when secrets exist', (done) ->
      this.timeout(TEST_TIMEOUT)
      secrets_payload =
        secrets:
          token: 'cmljYXJkbzpteXBhc3M='
        user_info:
          id: user_id
        integration_info:
          name: integration_name

      path = '/secrets/' +
        user_id + '/' +
        integration_name

      nock(auth_service_endpoint)
      .get(path)
      .reply(200, secrets_payload)

      success_reply = 'You successfully executed command for integration ' +
        integration_name

      authenticated_command = (msg, robot) ->
        try
          expect(msg).to.exist
          expect(msg.auth).to.exist
          expect(msg.auth.secrets).to.exist
          expect(msg.auth.user_info).to.exist
          expect(msg.auth.integration_info).to.exist
          expect(msg.auth.secrets.token).to.exist
          expect(msg.auth.user_info.id).to.exist
          expect(msg.auth.integration_info.name).to.exist
          expect(robot).to.exist
          msg.reply success_reply
        catch e
          msg.reply e.toString()

      # Authentication is enabled be default for this command
      @room.robot.e.create(command_params, authenticated_command)
      msg_interaction = [
        [user_id, '@hubot basic_auth get something'],
        ['hubot', '@' + user_id + ' ' + success_reply]
      ]
      messages = @room.messages
      @room.user.say(msg_interaction[0][0], msg_interaction[0][1]).then ->
        setTimeout(() ->
          expect(messages).to.eql msg_interaction
          done()
        ASYNC_MESSAGE_TIMEOUT)
      .catch (e) ->
        done(e)

    it 'should send error message to user if endpoint of auth ' +
        'service is not available', (done) ->
      this.timeout(TEST_TIMEOUT)

      # Authentication is enabled be default for this command
      @room.robot.e.create(command_params, command_should_not_run)

      path = '/secrets/' +
        user_id + '/' +
        integration_name

      e1 = new Error('connect ECONNREFUSED 127.0.0.1:443')

      nock(auth_service_endpoint)
      .get(path)
      .replyWithError(e1)

      expectedError = commons.authentication_error_message(e1)

      conversation = [
        ['pedro', '@hubot basic_auth get something'],
        ['hubot', '@pedro ' + expectedError]
      ]

      messages = @room.messages
      @room.user.say(conversation[0][0], conversation[0][1])
      .then ->
        setTimeout(() ->
          expect(messages).to.eql(conversation)
          done()
        ASYNC_MESSAGE_TIMEOUT)
      .catch (e) ->
        done(e)

    it 'should send error message to user if auth service responds ' +
        'errors other than 404', (done) ->
      this.timeout(TEST_TIMEOUT)

      path = '/secrets/' +
        user_id + '/' +
        integration_name

      response =
        message: 'There was an internal server error while ' +
          'retrieving secrets at ' + path

      nock(auth_service_endpoint)
      .get(path)
      .reply(500, response)

      # Authentication is enabled be default for this command
      @room.robot.e.create(command_params, command_should_not_run)

      expectedError = commons.authentication_error_message(
        new Error(auth_service.client.UNEXPECTED_STATUS_CODE + '500'))

      conversation = [
        ['pedro', '@hubot basic_auth get something'],
        ['hubot', '@pedro ' + expectedError]
      ]
      messages = @room.messages
      @room.user.say(conversation[0][0], conversation[0][1])
      .then ->
        setTimeout(() ->
          expect(messages).to.eql(conversation)
          done()
        ASYNC_MESSAGE_TIMEOUT)
      .catch (e) ->
        done(e)

    it 'should send error to user when auth service fail to ' +
        'generate token_url', (done) ->
      this.timeout(TEST_TIMEOUT)

      path = '/secrets/' +
        user_id + '/' +
        integration_name

      response =
        message: 'Error retrieving secrets at ' + path

      token_response =
        message: 'High volume of requests, server unavailable.' +
          ' Please try again later.'

      nock(auth_service_endpoint)
      .get(path)
      .reply(404, response)

      nock(auth_service_endpoint)
      .post('/token_urls')
      .reply(500, token_response)

      # Authentication is enabled be default for this command
      @room.robot.e.create(command_params, command_should_not_run)

      expectedError = commons.authentication_error_message(
        new Error(auth_service.client.UNEXPECTED_STATUS_CODE + '500'))

      conversation = [
        ['pedro', '@hubot basic_auth get something'],
        ['hubot', '@pedro ' + commons.authentication_announcement(command)],
        ['hubot', '@pedro ' + expectedError]
      ]

      messages = @room.messages
      @room.user.say(conversation[0][0], conversation[0][1])
      .then ->
        setTimeout(() ->
          expect(messages).to.eql(conversation)
          done()
        ASYNC_MESSAGE_TIMEOUT)
      .catch (e) ->
        done(e)

    it 'should send error to user when auth service is not available to' +
        'generate token_url', (done) ->
      this.timeout(TEST_TIMEOUT)

      path = '/secrets/' +
        user_id + '/' +
        integration_name

      response =
        message: 'Error retrieving secrets at ' + path

      nock(auth_service_endpoint)
      .get(path)
      .reply(404, response)

      e1 = new Error('connect ECONNREFUSED 127.0.0.1:443')

      nock(auth_service_endpoint)
      .post('/token_urls')
      .replyWithError(e1)

      # Authentication is enabled be default for this command
      @room.robot.e.create(command_params, command_should_not_run)

      expectedError = commons.authentication_error_message(e1)

      conversation = [
        ['pedro', '@hubot basic_auth get something'],
        ['hubot', '@pedro ' + commons.authentication_announcement(command)]
        ['hubot', '@pedro ' + expectedError]
      ]

      messages = @room.messages
      @room.user.say(conversation[0][0], conversation[0][1])
      .then ->
        setTimeout(() ->
          expect(messages).to.eql(conversation)
          done()
        ASYNC_MESSAGE_TIMEOUT)
      .catch (e) ->
        done(e)

    it 'should send user a token_url if secrets not found ' +
        '(not authenticated)', (done) ->
      this.timeout(TEST_TIMEOUT)

      path = '/secrets/' +
        user_id + '/' +
        integration_name

      response =
        message: 'Error retrieving secrets at ' + path

      portal_endpoint = 'https://he-portal.hpe.com'
      portal_path = '/portal'
      token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.' +
        'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iO' +
        'nRydWV9.TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ'
      token_response =
        message: 'token_url created'
        token: token
        url: portal_endpoint + portal_path + '/' + token

      nock(auth_service_endpoint)
      .get(path)
      .reply(404, response)

      nock(auth_service_endpoint)
      .post('/token_urls')
      .reply(201, token_response)

      # Authentication is enabled be default for this command
      @room.robot.e.create(command_params, command_should_not_run)

      expectedMsg = commons.authentication_message(command, token_response.url)

      conversation = [
        ['pedro', '@hubot basic_auth get something'],
        ['hubot', '@pedro ' + commons.authentication_announcement(command)],
        ['hubot', '@pedro ' + expectedMsg]
      ]

      messages = @room.messages
      @room.user.say(conversation[0][0], conversation[0][1])
      .then ->
        setTimeout(() ->
          expect(messages).to.eql(conversation)
          done()
        ASYNC_MESSAGE_TIMEOUT)
      .catch (e) ->
        done(e)
