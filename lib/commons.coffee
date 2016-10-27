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

# common strings object
class Commons
  no_such_integration: (product) ->
    return "there is no such integration *#{product}*"
  no_such_verb: (product, verb) ->
    return "there is no such verb *#{verb}* for integration *#{product}*"
  no_such_entity: (product, verb, entity) ->
    return "there is no such entity *#{entity}* for verb *#{verb}* "+
      "of *#{product}*"
  did_you_mean: (name) ->
    return ", did you mean *#{name}*?"
  help_msg: (content) ->
    return "help for hubot enterprise:\n"+content
  authentication_message: (command, url) ->
    return "To issue \`#{command}` I need permission to access your account. " +
      "To do so, please visit the Hubot Enterprise Identity Portal" +
      " at #{url}"
  authentication_announcement: (command) ->
    return "To issue \`#{command}` I need permission to access your account. " +
      "A private message will be sent to you."
  authentication_error_message: (e) ->
    return 'There was an error trying to authenticate ' +
        'your user in Hubot Enterprise. Please contact your system ' +
        'administration and' +
        ' provide him \/ her this error message: ' + e.toString()

module.exports = Commons
