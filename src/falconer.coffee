{EventEmitter} = require 'events'
{Request} = require './request'
http = require 'http'


EVENTS_HEADER        = 'x-falconer-events'
EVENTS_ACCEPT_HEADER = 'x-falconer-accept-events'

class Falconer extends EventEmitter

  constructor: (options={}) ->
    super 
    @host = options.host
    @port = options.port ? 80
    @cascade404 = true
    @poll = options.poll ? false
    @pollPath = options.pollPath ? '/@falconer-poll'
    @pollInterval = options.pollInterval ? 1000

    @pollEvents()

  pollEvents: =>
    if @poll
      @get(@pollPath).complete =>
        setTimeout @pollEvents, @pollInterval

  # Connect middleware hook
  handle: (req, res, next) ->
    @proxy(req, res, next)

  # Handle incoming events headers
  handleEvents: (response) =>
    eventsHeaderStr = response.headers[EVENTS_HEADER]
    delete response.headers[EVENTS_HEADER]

    return unless eventsHeaderStr
    process.nextTick =>
      try
        events = JSON.parse eventsHeaderStr 
        for [event, data] in events
          @emit event, data
      catch e
        throw e unless e.name is 'SyntaxError'
        console.log 'Could not parse', eventsHeaderStr

  # Proxy a given request
  proxy: (req, res, next) ->
    # Signal that this request will accept events
    req.headers[EVENTS_ACCEPT_HEADER] = '1'

    # Set forwarded host and update host
    req.headers['x-forwarded-host'] = req.headers['host']
    req.headers['host'] = @host

    request = http.request
      host: @host
      port: @port
      method: req.method
      path: req.url
      headers: req.headers

    request.on 'response', (response) =>
      @handleEvents response

      if response.statusCode is 404 and @cascade404
        next()
      else
        res.writeHead response.statusCode, response.headers
        response.pipe(res)

    req.pipe(request)



  # Makes HTTP request to target server
  request: (method, path) ->
    request = new Request(@host, @port)[method.toLowerCase()](path)
      .on('response', @handleEvents)
      .header(EVENTS_ACCEPT_HEADER, '1')



# Generate methods for common HTTP verbs
for method in ['get', 'post', 'put', 'delete']
  do (method) ->
    Falconer::[method] = (path) ->
      @request(method.toUpperCase(), path)


module.exports = 
  Falconer: Falconer
