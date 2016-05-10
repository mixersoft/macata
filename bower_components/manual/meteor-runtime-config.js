/**
*

  // To install Meteor server, use mupx
  // see: https://github.com/arunoda/meteor-up/tree/mupx

*
*/


setMeteorRuntime = function(){
  var runConfig, hostname, port, connect, oauthProxy;
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
      oauthProxy = "http://10.0.2.2/"
      break;
  }
  connect = ['http://', hostname, ':', port, '/'].join('');

  window.__meteor_runtime_config__ = angular.extend( {}, window.__meteor_runtime_config__, {
    LABEL: runConfig,
    DDP_DEFAULT_CONNECTION_URL: connect,
    OAUTH_PROXY: oauthProxy || connect
  });

  return
}

setMeteorRuntime();

// meteorServer = ['http://', window.location.hostname, ':3333']
// __meteor_runtime_config__ = {};
// __meteor_runtime_config__.DDP_DEFAULT_CONNECTION_URL = meteorServer.join('');
