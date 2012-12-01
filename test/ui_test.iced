{ ok, equal, deepEqual } = require 'assert'
assert                   = require 'assert'

LiveReloadContext = require "../#{process.env.JSLIB or 'lib'}/context"
TestScriptTransport = require "../#{process.env.JSLIB or 'lib'}/rpc/transports/testscript"


describe "LiveReload UI", ->

  it "should start up", (done) ->
    transport = new TestScriptTransport [
      ['o app.request_model', {}]
      ['o update', { projects: [] }]
      ['o rpc', {"#mainwnd":{"#textBlockStatus":{"text":"Idle. 0 browsers connected. 0 changes, 0 files compiled, 0 refreshes so far."}}}]
      ['o rpc', {"#mainwnd":{"#treeViewProjects":{"data":[]}}}]
      ['o rpc', {"#mainwnd":{"#buttonProjectAdd":{"enabled":true},"#buttonProjectRemove":{"enabled":false}}}]
      ['o rpc', {"#mainwnd":{"#checkBoxCompile":{"value":false,"enabled":true},"#tabs":{"visible":false}}}]
      ['o rpc', {"#mainwnd":{"#textBoxSnippet":{"text":""}}}]
      ['o rpc', {"#mainwnd":{"#textBoxUrl":{"text":""}}}]
      ['o rpc', {"#mainwnd":{"#buttonSetOutputFolder":{},"#treeViewPaths":{"data":[]}}}]
    ]

    options = {}
    context = new LiveReloadContext()
    context.setupRpc(transport)

    global.LR = require('../config/env').createEnvironment(options, context)

    exit = ->
      done()

    await LR.app.api.init.call context, {
      resourcesDir: context.paths.bundledPlugins,
      appDataDir: process.env['TMPDIR'],
      logDir: process.env['TMPDIR']
      version: '0.0.7'
    }, defer(err)
    assert.ifError err

    transport.on 'done', done
