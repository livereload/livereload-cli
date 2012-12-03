{ ok, equal, deepEqual } = require 'assert'
assert                   = require 'assert'
scopedfs                 = require 'scopedfs'

LiveReloadContext = require "../#{process.env.JSLIB or 'lib'}/context"
MockTransport = require "../#{process.env.JSLIB or 'lib'}/rpc/transports/mock"


class TestContext

  constructor: ->
    { @i, @o, @reply, @timeout, @transport } = new MockTransport(strict: yes)

    @context = new LiveReloadContext()
    @context.setupRpc(@transport)

    global.LR = require('../config/env').createEnvironment({}, @context)

    @tempfs = scopedfs.createTempFS('livereload-tests-')

    @startup = @startup.bind(this)

  startup: (callback) ->
    LR.app.api.init.call @context, {
      resourcesDir: @context.paths.bundledPlugins,
      appDataDir: @tempfs.path,
      logDir: process.env['TMPDIR']
      version: '0.0.7'
    }, callback


describe "LiveReload UI", ->

  it "should start up", (done) ->
    { i, o, reply, timeout, startup, context } = new TestContext()

    await
      o 'app.request_model', {}, defer()
      o 'update', { projects: [] }, defer()
      o 'rpc', {
        "#mainwnd":
          "#textBlockStatus":
            "text": "Idle. 0 browsers connected. 0 changes, 0 files compiled, 0 refreshes so far."
          "#treeViewProjects":
            "data": []
          "#buttonProjectAdd":
            "enabled": true
          "#buttonProjectRemove":
            "enabled": false
          "#tabs":
            "visible": false
          "#checkBoxCompile":
            "value": false
            "enabled": true
          "#textBoxSnippet":
            "text": ""
          "#textBoxUrl":
            "text": ""
          "#treeViewPaths":
            "data": []
          "#buttonSetOutputFolder": {}
        }, defer()
      timeout()
      startup defer(err)
    assert.ifError err

    await
      i 'rpc', '#mainwnd': '#buttonProjectAdd': click: yes
      o 'rpc', '#mainwnd': '!chooseOutputFolder': [{ initial: null }], defer()

    await
      reply { ok: yes, path: '/tmp/foo' }
      o 'rpc',
        '#mainwnd':
          '#textBlockStatus':
            text: "selected = /tmp/foo"
          "#treeViewProjects":
            "data": [
              {
                id: "P1_foo"
                text: "foo MEOW"
              }
            ]
      , defer()
      timeout()

    await context.session.after defer()

    done()
