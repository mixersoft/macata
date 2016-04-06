/**
*

  // To install Meteor server, use mupx
  // see: https://github.com/arunoda/meteor-up/tree/mupx

*
*/


setMeteorRuntime = function(){
  var runConfig, hostname, port, connect;
  switch (window.location.hostname) {
    case 'localhost':
      runConfig = "DEV";
      hostname = window.location.hostname;
      port = '3333';
      break;
    case 'app.snaphappi.com':
      runConfig = "BROWSER";
      hostname = window.location.hostname
      port = '3333';
      break;
    case "":
      runConfig = "DEVICE";
      hostname = 'app.snaphappi.com';
      port = '3333';
      break;
  }
  connect = ['http://', hostname, ':', port].join('')

  __meteor_runtime_config__ = {};
  __meteor_runtime_config__.LABEL = runConfig;
  __meteor_runtime_config__.DDP_DEFAULT_CONNECTION_URL = connect;

  return
}

setMeteorRuntime();

// meteorServer = ['http://', window.location.hostname, ':3333']
// __meteor_runtime_config__ = {};
// __meteor_runtime_config__.DDP_DEFAULT_CONNECTION_URL = meteorServer.join('');
