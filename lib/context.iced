Path    = require 'path'
Session = require 'livereload-core'

RPC = require './rpc/rpc'
JSONStreamTransport = require './rpc/transports/jsonstream'

class LiveReloadContext

  constructor: ->
    @universe = new Session.R.Universe()
    @session = @universe.create(Session)

    @paths = {}
    @paths.root = Path.dirname(__dirname)
    @paths.rpc  = Path.join(@paths.root, 'rpc-api')

    @paths.bundledPlugins = process.env.LRBundledPluginsOverride || Path.join(@paths.root, 'plugins')
    @session.addPluginFolder @paths.bundledPlugins

  setupRpc: ->
    @rpc = new RPC(new JSONStreamTransport(process.stdin, process.stdout))
    @rpc.on 'end', -> process.exit(0)

module.exports = LiveReloadContext
