connect = require 'connect'
NOOP = (req, res, next) -> next(req, res)

class Server
  constructor: (@port) ->
    @app = connect()
    @app.use @handler
    @reset()
    @port ?= 7462

  reset: ->
    @before_hook = NOOP
    @after_hook = NOOP
    @events = []

  start: (cb = -> ) =>
    @reset()
    @server = @app.listen(@port, cb)
    

  stop: (cb = -> ) =>
    @server.on 'close', cb
    @server.close()


  handler: (req, res, next) =>
    @before_hook req, res, =>
      if req.headers['x-falconer-accept-events']
        res.setHeader 'x-falconer-events', JSON.stringify(@events)

      @after_hook req, res, =>
        res.end "#{req.method} #{req.url}"

module.exports = Server

