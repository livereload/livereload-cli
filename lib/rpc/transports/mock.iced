debug = require('debug')('livereload:rpc')
{ ok } = require 'assert'
{ EventEmitter } = require 'events'
_ = require 'underscore'

SCORE_NO_MATCH  = 0
SCORE_CMD_MATCH = 10
SCORE_WILDCARD  = 900
SCORE_EXACT     = 1000


stableOrderReplacer = (key, value) ->
  return value unless value.constructor is Object
  Object.keys(value).sort().reduce (sorted, key) ->
    sorted[key] = value[key]
    sorted
  , {}


class Expectation
  constructor: (@ordinal, @callback, @command, @arg) ->
    @argString = JSON.stringify(@arg, stableOrderReplacer)

  toString: ->
    "Expectation(#{JSON.stringify(@command)}, #{@argString})"

  score: (command, arg) ->
    if @command isnt command
      SCORE_NO_MATCH
    else if @arg is '*'
      SCORE_WILDCARD
    else if (JSON.stringify(arg, stableOrderReplacer) != @argString)
      SCORE_CMD_MATCH
    else
      SCORE_EXACT


module.exports =
class MockTransport extends EventEmitter
  constructor: (options={}) ->
    @strict = options.strict ? no
    @messages = []
    @expectations = []
    @nextOrdinal = 1

    @i = @i.bind(this)
    @o = @o.bind(this)
    @timeout = @timeout.bind(this)
    @transport = this  # make life easy for those using destructive assingments

  send: (message) ->
    @messages.push message
    @emit 'sent', message

    best = { expectation: null, score: 0 }
    for expectation in @expectations
      score = expectation.score(message[0], message[1])
      if score > best.score
        best = { expectation, score }

    if best.score >= SCORE_WILDCARD
      if best.score is SCORE_EXACT
        debug "Exact expectation match for %j", message
      else
        debug "Wildcard expectation match for %j, arg wildcard %j", message, best.expectation.arg
      @_matched(best.expectation)
    else
      if best.score < SCORE_CMD_MATCH
        debug "No match for %j", message
      else
        debug "No match for the arg of %j", message
      if @strict
        ok no, "Unexpected message received: #{JSON.stringify(message)}"

  simulate: (message) ->
    @emit 'message', message

  expect: (command, arg, callback) ->
    if typeof callback isnt 'function'
      throw new Error "MockTransport#expect 3rd argument (callback) must be a function"
    @expectations.push new Expectation(@nextOrdinal++, callback, command, arg)

  _matched: (expectation) ->
    @expectations = _.without @expectations, expectation
    expectation.callback()


  o: (commad, arg, callback) -> @expect(commad, arg, callback)
  i: (commad, arg) -> @simulate([commad, arg])

  timeout: (period=50) ->
    limit = @nextOrdinal
    setTimeout (=>
      unmatched = @expectations.filter((e) -> e.ordinal < limit)
      if unmatched.length > 0
        ok no, "Expected commands not received within #{period}ms:" + ("\n#{expectation}" for expectation in unmatched).join('')
    ), period
