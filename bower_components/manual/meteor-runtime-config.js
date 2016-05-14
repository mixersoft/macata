/**
*

  // To install Meteor server, use mupx
  // see: https://github.com/arunoda/meteor-up/tree/mupx

*
*/


setMeteorRuntime = function(){
  var runConfig, hostname, port, connect, settings, oauth_rootUrl;

  switch (window.location.hostname) {
    case 'localhost':
      runConfig = "DEV";
      hostname = window.location.hostname;
      port = '3333';
      connect = ['http://', hostname, ':', port, '/'].join('');
      oauth_rootUrl = ['http://', hostname, ':', '3000', '/'].join('');
      break;
    case 'app.snaphappi.com':
      runConfig = "BROWSER";
      hostname = window.location.hostname
      port = '3333';
      connect = ['http://', hostname, ':', port, '/'].join('');
      oauth_rootUrl = ['http://', hostname, '/macata.App/'].join('');
      break;
    default:
      if (ionic.Platform.isWebView() == false) {
        console.error("ERROR: unknown runtime configuration");
        break;
      }
      runConfig = "DEVICE";
      hostname = 'app.snaphappi.com';
      port = '3333';
      connect = ['http://', hostname, ':', port, '/'].join('');
      // accounts-facebook-cordova does NOT use oauth redirect_uri
      oauth_rootUrl = '';
      break;
  }

  // copy additional settings from Meteor settings.json
  settings = {
    "public": {
      "label": runConfig,
      "facebook": {
        "oauth_rootUrl": oauth_rootUrl
      }
    }
  };

  window.__meteor_runtime_config__ = angular.extend( {}, window.__meteor_runtime_config__, {
    LABEL: runConfig,
    DDP_DEFAULT_CONNECTION_URL: connect,
    PUBLIC_SETTINGS: settings["public"]
  });

  return
}

setMeteorRuntime();

// meteorServer = ['http://', window.location.hostname, ':3333']
// __meteor_runtime_config__ = {};
// __meteor_runtime_config__.DDP_DEFAULT_CONNECTION_URL = meteorServer.join('');
