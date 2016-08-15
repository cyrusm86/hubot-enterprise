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
