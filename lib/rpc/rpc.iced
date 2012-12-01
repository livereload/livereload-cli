{ EventEmitter } = require 'events'

module.exports =
class RPC extends EventEmitter

  constructor: (@transport) ->
    @callbackTimeout = 2000
    @nextCallbackId = 1
    @callbacks = {}
    @timeouts  = {}
    @commandsInFlight = 0

    @transport.on 'message', (message) =>
      @executeWithProtection message

    @transport.on 'end', =>
      @emit 'end'


  registerCallback: (callback) ->
    callbackId = "$" + @nextCallbackId++
    @callbacks[callbackId] = callback
    return callbackId

  freeCallback: (callbackId) ->
    delete @callbacks[callbackId]
    if timerId = @timeouts[callbackId]
      clearTimeout(timerId)
      delete @timeouts[callbackId]

  registerOneTimeCallback: (callback, timeout) ->
    wrapperCallback = (args...) =>
      @freeCallback(callbackId)
      return callback(null, args...)

    callbackId = @registerCallback(wrapperCallback)

    if timeout
      @timeouts[callbackId] = setTimeout((-> wrapperCallback new Error("timeout")), @callbackTimeout)

    return callbackId


  send: (message, arg, callback=null) ->
    if typeof message isnt 'string'
      throw new Error("Invalid type of message: #{message}")

    self = this
    Function::toJSON = -> self.registerCallback(this)

    if callback  #args.length > 0 && typeof args[args.length - 1] is 'function'
      # timeouts temporarily disabled because they prevent displayPopupMessage call from returning useful data
      timeout = null
      @transport.send [message, arg, @registerOneTimeCallback(callback, timeout)]
    else
      @transport.send [message, arg]

    delete Function::toJSON


  executeWithProtection: (message) ->
    try
      await @execute(message, defer(err))
      if err
        @handleException err
    catch e
      @handleException e

  handleException: (err) ->
    @emit 'error', err


  execute: ([command, arg], callback) ->
    if command && typeof command is 'string'
      if command[0] is '$'
        @executeCallback(command, arg, callback)
      else if command[0] is '-'
        @freeCallback(command.substr(1))
      else
        @executeCommand(command, arg, callback)
    else
      callback(new Error("Invalid JSON received"))


  executeCallback: (command, arg, callback) ->
    if func = @callbacks[command]
      func arg
      callback(null)
    else
      callback(new Error("Unknown or duplicate callback received"))


  executeCommand: (command, arg, callback) ->
    ++@commandsInFlight

    await @emit('command', command, arg, defer(err))

    --@commandsInFlight

    # emit on next tick so that the callback has time to run first
    # (useful for testing, so that the callback can be the first to throw an assertion)
    if @commandsInFlight is 0
      process.nextTick =>
        if @commandsInFlight is 0
          @emit 'idle'

    callback(err)
