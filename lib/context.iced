Path    = require 'path'
Session = require 'livereload-core'

class LiveReloadContext

  constructor: ->
    @universe = new Session.R.Universe()
    @session = @universe.create(Session)

    @paths = {}
    @paths.root = Path.dirname(__dirname)
    @paths.rpc  = Path.join(@paths.root, 'rpc-api')

    @paths.bundledPlugins = process.env.LRBundledPluginsOverride || Path.join(@paths.root, 'plugins')
    @session.addPluginFolder @paths.bundledPlugins

module.exports = LiveReloadContext
