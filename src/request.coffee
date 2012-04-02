http = require 'http'
{EventEmitter} = require 'events'
class Request extends EventEmitter

  constructor: (@host, @port=80) ->
    super
    @method = 'INVALID'
    @path = null
    @sent = false
    @completed = false
    @headers = {}
    @data = []

    @on 'complete', => @completed = true


  request: (@method, @path) ->
    @

  header: (header, value) ->
    if value? 
      @headers[header] = value
    else
      for key, value of header
        @headers[key] = value
    @


  json: (payload) ->
    @data = [JSON.stringify(payload)]
    @header('Content-Type', 'application/json')
    @header('Content-Length', @data[0].length)


  complete: (callback) ->
    if @completed
      callback? @res
      @
    else
      @on 'complete', callback if callback
      @send()

  # Impersonate socket.io socket
  socket: (socket) ->
    if socket.handshake?.headers?.cookie
      @header('cookie', socket.handshake.headers.cookie)
    @

    

  send: ->
    return @ if @sent

    @req = http.request
      host: @host
      port: @port
      headers: @headers
      method: @method
      path: @path
    
    @req.on 'response', (@res) =>
      @emit 'response', @res

      # Capture Body
      @res.body = ''
      @res.on 'data', (chunk) => @res.body += chunk
      @res.on 'end', =>
        @completed = true
        @emit 'complete', @res

    @req.write(chunk) for chunk in @data

    @req.end()
    @

# request.get(/path)
# request.put(/path)
# request.post(/path)
# request.delete(/path)
for method in ['get', 'put', 'post', 'delete']
  do (method) ->
    Request::[method] = (path) ->
      @request method.toUpperCase(), path

module.exports.Request = Request
