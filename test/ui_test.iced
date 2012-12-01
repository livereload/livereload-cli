{ ok, equal, deepEqual } = require 'assert'
assert                   = require 'assert'

LiveReloadContext = require "../#{process.env.JSLIB or 'lib'}/context"


describe "LiveReload UI", ->

  it "should woot", ->
    options = {}
    context = new LiveReloadContext()

    global.LR = require('../config/env').createEnvironment(options, context)
    LR.rpc.init(process, process.exit, context: context, consoleDebuggingMode: true)
    await LR.app.api.init.call context, {
      resourcesDir: context.paths.bundledPlugins,
      appDataDir: context.paths.bundledPlugins,
      logDir: process.env['TMPDIR']
    }, defer(err)
    assert.ifError err

    ok true
