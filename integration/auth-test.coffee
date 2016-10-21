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

# Disable TLS / SSL self-signed certificate warning.
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

Helper = require 'hubot-test-helper'
chai = require 'chai'
auth_lib = require '../lib/authentication.coffee'
commons = new (require('../lib/commons.coffee'))()
jose = require('node-jose')
fs = require('fs')
path = require('path')

Promise = require('bluebird')
jwt = Promise.promisifyAll(require('jsonwebtoken'))

expect = chai.expect

process.env[auth_lib.env.ENABLE] = 1
auth_service_endpoint = 'https://localhost:3000/'
process.env[auth_lib.env.ENDPOINT] = auth_service_endpoint
helper = new Helper(['../src/0_bootstrap.coffee'])


encrypt_as_jwe = (key, payload, cb) ->
  opts =
    format: 'compact'
  keystore = jose.JWK.createKeyStore()

  keystore.add(key, 'pem', {use: 'enc'}).then (jwe_key) ->
    jose.JWE.createEncrypt(opts, jwe_key)
    .update(JSON.stringify(payload)).final()
    .then (jwe_token) ->
      cb(null, jwe_token)
    .catch (e) ->
      cb(e, null)
  .catch (e) ->
    cb(e, null)

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
    auth_client = auth_lib.setup_auth_client()

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

    secrets =
      username: 'my_integration_username'
      password: 'my_integration_password'

    command_should_not_run = (msg) ->
      msg.reply should_fail_message


    TEST_TIMEOUT = 20000
    ASYNC_MESSAGE_TIMEOUT = 5000

    jwt_key = fs.readFileSync(path.join(__dirname, '../certs/jwt_token.pem'))
    jwe_key = fs.readFileSync(path.join(__dirname,
      './../certs/jwe_token_url_pub.pem'))
    jwe_secrets_key = fs.readFileSync(path.join(__dirname,
      './../certs/jwe_secrets_pub.pem'))

    jwe_token = ''
    jwe_secrets = ''

    before (done) ->
      jwt_payload =
        user_info:
          id: user_id
        integration_info:
          name: integration_name

      jwt_opts =
        algorithm: 'RS256'


      jwt.sign jwt_payload, jwt_key, jwt_opts, (err, jwt_token) ->
        if err
          return done(err)

        encrypt_as_jwe jwe_key, jwt_token, (err, resp) ->
          if (err)
            return done(err)

          jwe_token = resp

          encrypt_as_jwe jwe_secrets_key, secrets, (err, enc_secrets) ->
            if (err)
              return done(err)
            jwe_secrets = enc_secrets
            done()

    beforeEach ->
      basic_auth = @room.robot.e.auth.generate_basic_auth({})
      @room.robot.e.registerIntegration(metadata, basic_auth)

    it 'should perform integration command when secrets exist', (done) ->
      this.timeout(TEST_TIMEOUT)

      secrets_payload =
        secrets: jwe_secrets
        token: jwe_token

      path = '/secrets/' +
          user_id + '/' +
          integration_name

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

      # POST secrets in the he-auth-service
      auth_client.saveSecretsAsync(secrets_payload).then ->
        console.log('success posting secrets')
        messages = @room.messages
        @room.user.say(msg_interaction[0][0], msg_interaction[0][1]).then ->
          expect_timeout = () ->
            expect(messages).to.eql msg_interaction
            done()
          setTimeout(expect_timeout, ASYNC_MESSAGE_TIMEOUT)
        .catch (e) ->
          done(e)
      .catch (e) ->
        done(e)

      # Needs this return statement to avoid returning a promise
      return

    it 'should send user a token_url if secrets not found ' +
        '(not authenticated)', (done) ->
      this.timeout(TEST_TIMEOUT)

      # Authentication is enabled be default for this command
      @room.robot.e.create(command_params, command_should_not_run)

      expectedMsg = commons.authentication_message(command, '')

      conversation = [
        ['pedro', '@hubot basic_auth get something'],
        ['hubot', '@pedro ' + expectedMsg]
      ]

      messages = @room.messages
      @room.user.say(conversation[0][0], conversation[0][1]).then ->
        expect_timeout = () ->
          expect(messages.length).to.equal(2)
          expect(messages[0]).to.eql(conversation[0])
          expect(messages[1][0]).to.eql(conversation[1][0])
          expect(messages[1][1]).to.contain(conversation[1][1])
          done()
        setTimeout(expect_timeout, ASYNC_MESSAGE_TIMEOUT)
      .catch (e) ->
        done(e)

      # Needs this return statement to avoid returning a promise
      return
