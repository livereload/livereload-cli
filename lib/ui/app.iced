debug   = require('debug')('livereload:cli')
_       = require 'underscore'
R       = require('livereload-core').R
UIModel = require './base'

MainWindow = require './mainwnd'
Stats      = require './stats'


module.exports =
class ApplicationUI extends UIModel

  schema:
    mainwnd: {}

  constructor: (@vfs, @session) ->
    super()
    @stats = new Stats()
    @mainwnd = new MainWindow(this, @session)
