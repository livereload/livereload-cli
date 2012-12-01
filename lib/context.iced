Session = require 'livereload-core'

class LiveReloadContext

  constructor: ->
    @universe = new Session.R.Universe()
    @session = @universe.create(Session)

module.exports = LiveReloadContext
