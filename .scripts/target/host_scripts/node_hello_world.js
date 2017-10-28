// node_hello_world.js
var http = require('http');
var server = http.createServer(function(req, res) {
  res.writeHead(200);
  res.end('<H1>Hello Meteor World !!</H1><UL/>');
});
server.listen(3000);
