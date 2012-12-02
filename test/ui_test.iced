{ ok, equal, deepEqual } = require 'assert'
assert                   = require 'assert'

LiveReloadContext = require "../#{process.env.JSLIB or 'lib'}/context"
MockTransport = require "../#{process.env.JSLIB or 'lib'}/rpc/transports/mock"


class TestContext

  constructor: ->
    { @i, @o, @timeout, @transport } = new MockTransport(strict: yes)

    @context = new LiveReloadContext()
    @context.setupRpc(@transport)

    global.LR = require('../config/env').createEnvironment({}, @context)

    @startup = @startup.bind(this)

  startup: (callback) ->
    LR.app.api.init.call @context, {
      resourcesDir: @context.paths.bundledPlugins,
      appDataDir: process.env['TMPDIR'],
      logDir: process.env['TMPDIR']
      version: '0.0.7'
    }, callback


describe "LiveReload UI", ->

  it "should start up", (done) ->
    { i, o, timeout, startup } = new TestContext()

    await
      o 'app.request_model', {}, defer()
      o 'update', { projects: [] }, defer()
      o 'rpc', {"#mainwnd":{"#textBlockStatus":{"text":"Idle. 0 browsers connected. 0 changes, 0 files compiled, 0 refreshes so far."}}}, defer()
      o 'rpc', {"#mainwnd":{"#treeViewProjects":{"data":[]}}}, defer()
      o 'rpc', {"#mainwnd":{"#buttonProjectAdd":{"enabled":true},"#buttonProjectRemove":{"enabled":false}}}, defer()
      o 'rpc', {"#mainwnd":{"#checkBoxCompile":{"value":false,"enabled":true},"#tabs":{"visible":false}}}, defer()
      o 'rpc', {"#mainwnd":{"#textBoxSnippet":{"text":""}}}, defer()
      o 'rpc', {"#mainwnd":{"#textBoxUrl":{"text":""}}}, defer()
      o 'rpc', {"#mainwnd":{"#buttonSetOutputFolder":{},"#treeViewPaths":{"data":[]}}}, defer()
      timeout()
      startup defer(err)
    assert.ifError err

    done()
