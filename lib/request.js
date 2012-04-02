(function() {
  var EventEmitter, Request, http, method, _fn, _i, _len, _ref,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  http = require('http');

  EventEmitter = require('events').EventEmitter;

  Request = (function(_super) {

    __extends(Request, _super);

    function Request(host, port) {
      var _this = this;
      this.host = host;
      this.port = port != null ? port : 80;
      Request.__super__.constructor.apply(this, arguments);
      this.method = 'INVALID';
      this.path = null;
      this.sent = false;
      this.completed = false;
      this.headers = {};
      this.data = [];
      this.on('complete', function() {
        return _this.completed = true;
      });
    }

    Request.prototype.request = function(method, path) {
      this.method = method;
      this.path = path;
      return this;
    };

    Request.prototype.header = function(header, value) {
      var key;
      if (value != null) {
        this.headers[header] = value;
      } else {
        for (key in header) {
          value = header[key];
          this.headers[key] = value;
        }
      }
      return this;
    };

    Request.prototype.json = function(payload) {
      this.data = [JSON.stringify(payload)];
      return this.header('Content-Type', 'application/json');
    };

    Request.prototype.complete = function(callback) {
      if (this.completed) {
        if (typeof callback === "function") callback(this.res);
        return this;
      } else {
        if (callback) this.on('complete', callback);
        return this.send();
      }
    };

    Request.prototype.send = function() {
      var chunk, _i, _len, _ref,
        _this = this;
      if (this.sent) return this;
      this.req = http.request({
        host: this.host,
        port: this.port,
        headers: this.headers,
        method: this.method,
        path: this.path
      });
      this.req.on('response', function(res) {
        _this.res = res;
        _this.emit('response', _this.res);
        _this.res.body = '';
        _this.res.on('data', function(chunk) {
          return _this.res.body += chunk;
        });
        return _this.res.on('end', function() {
          _this.completed = true;
          return _this.emit('complete', _this.res);
        });
      });
      _ref = this.data;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        chunk = _ref[_i];
        this.req.write(chunk);
      }
      this.req.end();
      return this;
    };

    return Request;

  })(EventEmitter);

  _ref = ['get', 'put', 'post', 'delete'];
  _fn = function(method) {
    return Request.prototype[method] = function(path) {
      return this.request(method.toUpperCase(), path);
    };
  };
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    method = _ref[_i];
    _fn(method);
  }

  module.exports.Request = Request;

}).call(this);
