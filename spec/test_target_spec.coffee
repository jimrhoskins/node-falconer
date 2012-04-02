require './support/http'
TargetServer = require './support/target_server'

describe 'Testing Support', ->
  describe 'TargetServer', ->

    target = new TargetServer
    beforeEach (done )-> target.start(done)
    afterEach (done) -> target.stop(done)

    it 'should not send events header ', (done) ->
      target.app.request()
        .get('/')
        .end (res) ->
          res.body.should.equal 'GET /'
          res.headers.should.not.have.property 'x-falconer-events'
          done()

    it 'should send events header when asked', (done) ->
      target.app.request()
        .get('/')
        .set('x-falconer-accept-events', '1')
        .end (res) ->
          res.body.should.equal 'GET /'
          res.should.have.header 'x-falconer-events'
          done()
