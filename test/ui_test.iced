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

  it "should start up and handle a typical use case", (done) ->
    { i, o, reply, startup, context } = new TestContext()


    ################################################################################################
    # start the app

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
      startup defer(err)
    assert.ifError err


    ################################################################################################
    # add a project

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

    await context.session.after defer()


    ################################################################################################
    # select a project

    await
      i 'rpc', '#mainwnd': '#treeViewProjects': selectedId: 'P1_foo'
      o 'rpc',
        '#mainwnd':
          "#buttonProjectAdd":
            "enabled": true
          "#buttonProjectRemove":
            "enabled": true
          "#tabs":
            "visible": true
          "#checkBoxCompile":
            "value": false
            "enabled": true
          "#textBoxSnippet":
            "text": "<script>document.write('<script src=\"http://' + (location.host || 'localhost').split(':')[0] + ':35729/livereload.js?snipver=2\"></' + 'script>')</script>"
          "#textBoxUrl":
            "text": ""
          "#buttonSetOutputFolder": {}
          "#treeViewPaths":
            "data": [
              {
                id: "rule-undefined"
                text: "Compile CoffeeScript:  **/*.coffee   →   **/*.js"
                children: []
              }
              {
                id: "rule-undefined"
                text: "Compile Eco:  **/*.eco   →   **/*.js"
                children: []
              }
              {
                id: "rule-undefined"
                text: "Compile HAML:  **/*.haml   →   **/*.html"
                children: []
              }
              {
                id: "rule-undefined"
                text: "Compile IcedCoffeeScript:  **/*.iced   →   **/*.js"
                children: []
              }
              {
                id: "rule-undefined"
                text: "Compile Jade:  **/*.jade   →   **/*.html"
                children: []
              }
              {
                id: "rule-undefined"
                text: "Compile LESS:  **/*.less   →   **/*.css"
                children: []
              }
              {
                id: "rule-undefined"
                text: "Compile SASS:  **/*.sass   →   **/*.css"
                children: []
              }
              {
                id: "rule-undefined"
                text: "Compile Compass:  **/*.sassco   →   **/*.css"
                children: []
              }
              {
                id: "rule-undefined"
                text: "Compile Slim:  **/*.slim   →   **/*.html"
                children: []
              }
              {
                id: "rule-undefined"
                text: "Compile Stylus:  **/*.styl   →   **/*.css"
                children: []
              }
            ]
      , defer()


    ################################################################################################
    # remove a project

    await
      i 'rpc', '#mainwnd': '#buttonProjectRemove': click: yes
      o 'rpc',
        '#mainwnd':
          "#treeViewProjects":
            "data": []
      , defer()


    ################################################################################################

    setTimeout done, 10  # catch any remaining messages
