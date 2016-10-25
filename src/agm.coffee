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
module.exports = (robot) ->
#  if not robot.e
#    robot.logger.error 'hubot-enterprise not present, cannot run'
#  return
  robot.logger.info 'hubot-agm loading'

  metadata =
    short_desc: 'AgM Example'
    long_desc: 'Showcases how to write an integration ' +
      'that uses BasicAuthentication'
    name: "agm"

  command_params =
    verb: 'get'
    entity: 'stories'
    type: 'respond'
    name: 'agm'

  # register integration
  basic_auth = robot.e.auth.generate_basic_auth({})
  robot.e.registerIntegration(metadata, basic_auth)

  respond_to_get_stories = (msg) ->
    msg.reply 'all your stories are belong to us'

  robot.e.create(command_params, respond_to_get_stories)
  robot.logger.info 'hubot-agm initialized'
