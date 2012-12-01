fs   = require 'fs'
path = require 'path'

{ EventEmitter }        = require 'events'
{ createApiTree }       = require 'apitree'
{ createRemoteApiTree } = require '../lib/remoteapitree'


get = (object, path) ->
  for component in path.split('.')
    object = object[component]
    throw new Error("Cannot find #{path}") if !object

  throw new Error("#{path} is not callable") unless object.call?
  object

execute = (message, args..., callback) ->
  if message is 'rpc'
    message = 'projects.rpc'

  message = message.replace /\.(\w+)$/, '.api.$1'
  try
    get(LR, message).apply(this, [args..., callback])
  catch e
    callback(e)


exports.createEnvironment = (options, context) ->
  LR = createApiTree(context.paths.rpc)

  LR.events = new EventEmitter()

  messages = JSON.parse(fs.readFileSync(path.join(__dirname, 'client-messages.json'), 'utf8'))
  messages.pop()
  LR.client = createRemoteApiTree(messages, (msg) -> (args...) -> context.rpc.send(msg, args...))

  LR.rpc = context.rpc
  LR.rpc.on 'command', execute.bind(context)

  LR
