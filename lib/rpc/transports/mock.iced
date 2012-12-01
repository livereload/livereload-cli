{ EventEmitter } = require 'events'

module.exports =
class MockTransport extends EventEmitter
  constructor: ->
    @messages = []

  send: (message) ->
    @messages.push message
    @emit 'sent', message

  simulate: (message) ->
    @emit 'message', message
