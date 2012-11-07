Session = require 'livereload-core'

class LiveReloadContext

  constructor: ->
    @universe = new Session.R.Universe()
    @session = new Session()

module.exports = LiveReloadContext
