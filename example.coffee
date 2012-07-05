{Falconer} = require './lib/falconer'
connect = require 'connect'

app = connect()


app.use new Falconer
  host: 'jimhoskins.com'
  port: 80
  poll: true

app.use "/fff", (req, res) ->
  res.end "Durrr"


app.listen(3344)
console.log 'Listening'
