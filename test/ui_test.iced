{ ok, equal, deepEqual } = require 'assert'
assert                   = require 'assert'

LiveReloadContext = require "../#{process.env.JSLIB or 'lib'}/context"


describe "LiveReload UI", ->

  it "should woot", (done) ->
    options = {}
    context = new LiveReloadContext()

    context.rpc =
      on: ->
      send: (msg, arg) ->
        console.log "got msg %j", msg

    global.LR = require('../config/env').createEnvironment(options, context)

    exit = ->
      done()

    await LR.app.api.init.call context, {
      resourcesDir: context.paths.bundledPlugins,
      appDataDir: context.paths.bundledPlugins,
      logDir: process.env['TMPDIR']
    }, defer(err)
    assert.ifError err

    done()
