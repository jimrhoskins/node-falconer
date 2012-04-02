should = require 'should'
TargetServer = require './support/target_server'

{Falconer} = require '../lib/falconer'
{Request}  = require '../lib/request'
connect = require 'connect'

read = (stream, callback) ->
  data = ''
  stream.on 'data', (chunk) -> data += chunk
  stream.on 'end', -> callback(data)

describe 'Falconer request',  ->
  target = new TargetServer
  beforeEach target.start
  afterEach target.stop

  falcon = new Falconer
    host: 'localhost'
    port: target.port


  it 'should proxy basic requests', (done) ->
    target.before_hook = (req, res, next) ->
      req.url.should.equal '/test/get'
      next(req, res)

    falcon.request('get', '/test/get')
      .complete (res) ->
        res.body.should.equal 'GET /test/get'
        done()


  it 'should accept json', (done) ->
    target.before_hook = (req, res, next) ->
      req.headers['content-type'].should.equal 'application/json'
      read req, (body) ->
        body.should.equal JSON.stringify payload
        next(req, res)
        done()

    payload = {foo: 'bar', baz: [1,2,3]}

    falcon.request('POST', '/example')
      .json(payload)
      .send()


  describe 'event handling', ->

    it 'should send falconer accept header with requests', (done) ->
      target.before_hook = (req, res, next) ->
        req.headers['x-falconer-accept-events'].should.equal '1'
        done()
        next(req, res)

      falcon.get('/foo')
        .send()

    it 'should emit events received during requests', (done) ->
      target.events = [['event1', {foo: 'bar'}]]

      falcon.on 'event1', (data) ->
        data.foo.should.equal 'bar'
        done()

      falcon.get('/foo').send()



  describe 'convenience method methods',  ->
    for method in ['get', 'put', 'post', 'delete']
      do (method) ->

        method_falcon = new Falconer
          host: 'localhost'
          port: 0

        it "should send #{method} to request", ->
          method_falcon.request = (meth, url) ->
            meth.should.equal method.toUpperCase()
            url.should.equal  'method/url'
            Falconer::request.call(method_falcon, meth, url)

          req = method_falcon[method]('method/url')
          req.should.be.an.instanceof Request



