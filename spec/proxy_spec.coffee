should = require 'should'
TargetServer = require './support/target_server'

{Falconer} = require '../lib/falconer'
connect = require 'connect'

read = (stream, callback) ->
  data = ''
  stream.on 'data', (chunk) -> data += chunk
  stream.on 'end', -> callback(data)

describe 'Falconer proxy',  ->
  target = new TargetServer
  beforeEach (done) -> target.start(done)
  afterEach (done) -> target.stop(done)



  falcon = new Falconer
    host: 'localhost'
    port: target.port

  source = connect([])
  source.use falcon

  it 'should not modify the body', (done) ->
    target.app.request().get('/proxytest').end (target_res) ->
      source.request().get('/proxytest').end (source_res) ->
        target_res.body.should.equal source_res.body
        done()

  it 'should not modify the headers', (done) ->
    target.app.request().get('/').end (target_res) ->
      source.request().get('/').end (source_res) ->
        for key in Object.keys(target_res.headers).concat(Object.keys(source_res.headers))
          target_res.headers[key].should.equal source_res.headers[key]
        done()

  it 'should send request body', (done) ->
    target.before_hook = (req, res, next) ->
      read req, (body) ->
        body.should.equal 'bodycontent'
        next(req, res)

    source.request()
      .post('/')
      .write('bodycontent')
      .end (res) ->
        res.body.should.equal 'POST /'
        done()

  it 'should always add the accept header to the proxied request', (done) ->
    target.before_hook = (req, res, next) ->
      req.should.have.header 'x-falconer-accept-events'
      next(req, res)

    source.request()
      .get('/')
      .end (res) -> done()



