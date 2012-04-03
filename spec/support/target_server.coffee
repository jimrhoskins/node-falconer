connect = require 'connect'
NOOP = (req, res, next) -> next(req, res)

PORT = 3000

class Server
  constructor: (@port) ->
    @app = connect()
    @app.use @handler
    @reset()
    @port ?= PORT += 1

  reset: ->
    @before_hook = NOOP
    @after_hook = NOOP
    @events = []

  start: (cb = -> ) =>
    @reset()
    @server = @app.listen(@port,cb)
    

  stop: (cb = -> ) =>
    @server.close()
    cb()


  handler: (req, res, next) =>
    @before_hook req, res, =>
      if req.headers['x-falconer-accept-events']
        res.setHeader 'x-falconer-events', JSON.stringify(@events)

      @after_hook req, res, =>
        res.end "#{req.method} #{req.url}"

module.exports = Server

