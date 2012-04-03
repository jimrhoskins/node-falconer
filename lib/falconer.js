(function() {
  var EVENTS_ACCEPT_HEADER, EVENTS_HEADER, EventEmitter, Falconer, Request, http, method, _fn, _i, _len, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  EventEmitter = require('events').EventEmitter;

  Request = require('./request').Request;

  http = require('http');

  EVENTS_HEADER = 'x-falconer-events';

  EVENTS_ACCEPT_HEADER = 'x-falconer-accept-events';

  Falconer = (function(_super) {

    __extends(Falconer, _super);

    function Falconer(options) {
      var _ref, _ref2, _ref3, _ref4;
      if (options == null) options = {};
      this.handleEvents = __bind(this.handleEvents, this);
      this.pollEvents = __bind(this.pollEvents, this);
      Falconer.__super__.constructor.apply(this, arguments);
      this.host = options.host;
      this.port = (_ref = options.port) != null ? _ref : 80;
      this.cascade404 = true;
      this.poll = (_ref2 = options.poll) != null ? _ref2 : false;
      this.pollPath = (_ref3 = options.pollPath) != null ? _ref3 : '/@falconer-poll';
      this.pollInterval = (_ref4 = options.pollInterval) != null ? _ref4 : 1000;
      this.pollEvents();
    }

    Falconer.prototype.pollEvents = function() {
      var _this = this;
      if (this.poll) {
        return this.get(this.pollPath).complete(function() {
          return setTimeout(_this.pollEvents, _this.pollInterval);
        });
      }
    };

    Falconer.prototype.handle = function(req, res, next) {
      return this.proxy(req, res, next);
    };

    Falconer.prototype.handleEvents = function(response) {
      var eventsHeaderStr,
        _this = this;
      eventsHeaderStr = response.headers[EVENTS_HEADER];
      delete response.headers[EVENTS_HEADER];
      if (!eventsHeaderStr) return;
      return process.nextTick(function() {
        var data, event, events, _i, _len, _ref, _results;
        try {
          events = JSON.parse(eventsHeaderStr);
          _results = [];
          for (_i = 0, _len = events.length; _i < _len; _i++) {
            _ref = events[_i], event = _ref[0], data = _ref[1];
            _results.push(_this.emit(event, data));
          }
          return _results;
        } catch (e) {
          if (e.name !== 'SyntaxError') throw e;
          return console.log('Could not parse', eventsHeaderStr);
        }
      });
    };

    Falconer.prototype.proxy = function(req, res, next) {
      var request,
        _this = this;
      req.headers[EVENTS_ACCEPT_HEADER] = '1';
      req.headers['x-forwarded-host'] = req.headers['host'];
      req.headers['host'] = this.host;
      request = http.request({
        host: this.host,
        port: this.port,
        method: req.method,
        path: req.url,
        headers: req.headers
      });
      request.on('response', function(response) {
        _this.handleEvents(response);
        if (response.statusCode === 404 && _this.cascade404) {
          return next();
        } else {
          res.writeHead(response.statusCode, response.headers);
          return response.pipe(res);
        }
      });
      return req.pipe(request);
    };

    Falconer.prototype.request = function(method, path) {
      var request;
      return request = new Request(this.host, this.port)[method.toLowerCase()](path).on('response', this.handleEvents).header(EVENTS_ACCEPT_HEADER, '1');
    };

    return Falconer;

  })(EventEmitter);

  _ref = ['get', 'post', 'put', 'delete'];
  _fn = function(method) {
    return Falconer.prototype[method] = function(path) {
      return this.request(method.toUpperCase(), path);
    };
  };
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    method = _ref[_i];
    _fn(method);
  }

  module.exports = {
    Falconer: Falconer
  };

}).call(this);
