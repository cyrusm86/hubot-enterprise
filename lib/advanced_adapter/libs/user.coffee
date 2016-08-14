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


# User Object to be implemented in adapters REST calls

class User
  # constructor accepts full user names
  constructor: (id = '', name = '', email = '',firstName = '',
  lastName = '') ->
    @id = id
    @name = name
    @email = email
    @firstName = firstName
    @lastName = lastName

  # return user full name (first+last)
  # opts: optional object for return
  #  delimiter: delimiter between first and last name, DEFAULT: ' '
  #  lastNameFirst: boolean, last name first or last, DEFAULT: false
  fullName: (opts)->
    opts = opts || {delimiter: ' ', lastNameFirst: false}
    ret = []
    if @firstName
      ret.push(@firstName)
    if @lastName
      ret.push(@lastName)
    if ret.length == 0
      ret.push(@name)
    # reverse array if lastNameFirst
    if opts.lastNameFirst
      ret.reverse()
    # return full name
    return ret.join(opts.delimiter)



module.exports = User
