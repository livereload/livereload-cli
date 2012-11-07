debug = require('debug')('livereload:cli')
_     = require 'underscore'
R     = require('livereload-core').R


module.exports =
class UIModel extends R.Model

  constructor: (@parentModel) ->
    super()

  SEND: (payload, callback) ->
    if @context
      upstream = {}
      upstream[@context] = payload
      payload = upstream
    if @parentModel
      @parentModel.SEND(payload, callback)
    else
      @emit 'update', payload, callback

  toString: ->
    "#{@constructor.name}(#{@context or 'root'})"

  receive: (payload) ->
    debug "#{this}.receive: #{JSON.stringify(payload)}"
    unhandled = {}
    for own key, value of payload
      if key.match /^#/
        if (child = @attributes[key.slice(1)])?
          value = child.receive(value)
      @_receiveDestructurizing value, [key]

    return unhandled

  _receiveDestructurizing: (payload, path) ->
    debug "#{this}._receiveDestructurizing: #{JSON.stringify(payload)} at path = #{JSON.stringify(path)}"
    unhandled = {}

    for own key, value of payload when key.match /^#/
      unh = @_receiveDestructurizing value, path.concat(key)
      if Object.keys(unh).length > 0
        unhandled[key] = unh

    for own key, value of payload when !key.match /^#/
      unless @_receiveSingle path, key, value
        unhandled[key] = value

    return unhandled

  _receiveSingle: (path, event, value) ->
    fname = 'on ' + path.concat([event]).join(' ')
    debug "#{this}._receiveSingle: #{JSON.stringify(path)}.#{event}, fname = '#{fname}'"
    if typeof @[fname] is 'function'
      @[fname].call(@, value)
    return no
