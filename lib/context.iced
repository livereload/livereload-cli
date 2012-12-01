Path    = require 'path'
Session = require 'livereload-core'

RPC = require './rpc/rpc'

class LiveReloadContext

  constructor: ->
    @universe = new Session.R.Universe()
    @session = @universe.create(Session)

    @paths = {}
    @paths.root = Path.dirname(__dirname)
    @paths.rpc  = Path.join(@paths.root, 'rpc-api')

    @paths.bundledPlugins = process.env.LRBundledPluginsOverride || Path.join(@paths.root, 'plugins')
    @session.addPluginFolder @paths.bundledPlugins

  setupRpc: (transport) ->
    @rpc = new RPC(transport)

module.exports = LiveReloadContext
