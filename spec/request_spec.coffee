{Request} = require('../lib/request')
TargetServer = require './support/target_server'

read = (stream, callback) ->
  body = ''
  stream.on 'data', (c) -> body += c
  stream.on 'end', -> callback(body)

describe 'Request', ->
  target= new TargetServer(3000)
  beforeEach (done) -> target.start(done)
  afterEach (done) -> target.stop(done)

  it 'should work with a basic get request', (done) ->
    req = new Request('localhost', target.port)
      .get('/hello')
      .complete (res) ->
        res.body.should.equal 'GET /hello'
        done()

  it 'should handle request headers', (done) ->
    target.before_hook = (req, res, next) ->
      for x in [1, 2, 3]
        req.headers["header#{x}"].should.equal "header#{x}-value"
      next(req, res)
      done()

    req = new Request('localhost', target.port)
      .get('/hello')
      .header('header1', 'header1-value')
      .header({
        'header2': 'header2-value'
        'header3': 'header3-value'
      })
        .send()

  describe 'method methods', ->
    # request.get(/path)
    # request.put(/path)
    # request.post(/path)
    # request.delete(/path)
    for method in ['get', 'post', 'put', 'delete']
      do (method) ->

        it "should have the method #{method}", (done) ->
          target.before_hook = (req, res, next) ->
            req.method.should.equal method.toUpperCase()
            done()
            next(req, res)

          req = new Request('localhost', target.port)[method]('/path')
            .send()


  describe 'sending json', ->

    it 'should send json encoded data as the body', (done) ->
      payload = {foo: [1,2,3], bar: "xyz", x: {1:2}}

      target.before_hook = (req, res, next) ->
        read req, (body) ->
          body.should.equal JSON.stringify(payload)
          done()

      req = new Request('localhost', target.port)
        .post('/jsontest')
        .json(payload)
        .send()

    it 'should set the content-type to application/json', (done) ->
      payload = {foo: [1,2,3], bar: "xyz", x: {1:2}}

      target.before_hook = (req, res, next) ->
        req.headers['content-type'].should.equal 'application/json'
        done()

      req = new Request('localhost', target.port)
        .post('/jsontest')
        .json(payload)
        .send()

    it 'should set the content-length correctly', (done) ->
      payload = {foo: [1,2,3], bar: "xyz", x: {1:2}}

      target.before_hook = (req, res, next) ->
        req.headers['content-length'].should.equal JSON.stringify(payload).length.toString()
        done()

      req = new Request('localhost', target.port)
        .post('/jsontest')
        .json(payload)
        .send()

  describe 'sending the request', ->

    it 'should send the request after .send() is called', (done) ->
      target.before_hook = (req, res, next) ->
        next(req, res)
        done()

      new Request('localhost', target.port)
        .get('/foo')
        .send()

    describe 'via complete()', ->

      it 'should return response in callback', (done) ->
        new Request('localhost', target.port)
          .get('/foo')
          .complete (response) -> 
            response.statusCode.should.equal 200
            done()

      it 'should set the body property of the response', (done) ->
        new Request('localhost', target.port)
          .get('/foo')
          .complete (response) -> 
            response.body.should.equal 'GET /foo'
            done()

      it 'should return call callback even if request is completed', (done) ->
        request = new Request('localhost', target.port)
          .get('/foo')
          .complete (response) -> 
            # call complete again
            request.complete (respons) ->
              response.body.should.equal 'GET /foo'
              done()


  it 'should accept a socket.io socket', (done) ->
    target.before_hook = (req, res, next) ->
      req.headers.cookie.should.equal 'cookie=value'
      next(req, res)
      done()

    socket = {handshake:{headers:{cookie: 'cookie=value'}}}

    request = new Request('localhost', target.port)
      .get('/foo')
      .socket(socket)
      .send()
