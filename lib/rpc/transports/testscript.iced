debug = require('debug')('livereload:rpc')
{ ok, equal, deepEqual } = require 'assert'
{ EventEmitter } = require 'events'

class ExpectAction
  constructor: (@transport, @command, @arg) ->

  run: ->

  sent: (actualMessage) ->
    # [actualCommand, actualArg] = actualMessage
    deepEqual actualMessage, [@command, @arg]
    @transport.nextAction()


class SimulateAction
  constructor: (@transport, @command, @arg) ->

  run: ->
    @transport.simulate [@command, @arg]
    @transport.nextAction()

  sent: (message) ->


class EndOfScriptAction
  constructor: (@transport) ->

  run: ->

  sent: (actualMessage) ->
    ok no, "No more commands expected, got: " + JSON.stringify(actualMessage)


module.exports =
class TestScriptTransport extends EventEmitter
  constructor: (script) ->
    @actions = @_parseScript(script)
    @nextAction()

  send: (message) ->
    @currentAction.sent(message)


  # API for actions

  nextAction: ->
    if @currentAction = @actions.shift()
      @currentAction.run()
    else
      @currentAction = new EndOfScriptAction()
      @emit 'done'

  simulate: (message) ->
    process.nextTick =>
      @emit 'message', message


  _parseScript: (script) ->
    actions =
      for [xcommand, args...] in script
        [directive, command] = xcommand.trim().split(/\s+/)
        switch directive
          when 'o' then new ExpectAction(this, command, args...)
          when 'i' then new SimulateAction(this, command, args...)
          else throw new Error "Invalid test script command: " + JSON.stringify(xcommand)
    return actions
