#Node Falconer [![Build Status](https://secure.travis-ci.org/jimrhoskins/node-falconer.png?branch=master)](http://travis-ci.org/jimrhoskins/node-falconer)

## Usage

		Falconer = require('falconer').Falconer

		// Create a Falconer instance for the upstream application
		var upstreamApp = new Falconer({
			host: 'myApp.example.com',
			port: 80
		});

		// The falconer client will proxy express/connect requests to your upstream app
		var app = require('express').createServer();
		// or
		var app = require('connect').createServer()

		// Add the client as a middleware to your app to enable proxy
		app.use(upstreamApp)

		// The falconer client will emit any events received from the upstream app
		upstreamApp.on('someUpstreamEvent', function(payload1, payload2){
			// handle events from upstream app
		})

		// You can also easily send HTTP requests to the upstream app
		// These will also query for events from the upstream app
		upstreamApp.get('/some/endpoint.json').complete(function(response){
			// response is an http.ClientResponse
			// response.body contains response body as a string
		})

		// More requests
		upstreamApp.post('/users.json').
			.json({user: {name: 'Jim Hoskins'}})
			.header('Accept', 'text/html, */*')
			.header({
				'Cookie': 'name=value',
				'custom-header': 'value'
			})
			.on('response', function(res){
				// before response data events
			})
			.complete(function(res){
				// response after response end event. 
				// includes response.body
			})
			

