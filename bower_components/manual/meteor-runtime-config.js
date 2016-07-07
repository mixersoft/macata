/**
*

  // To install Meteor server, use mupx
  // see: https://github.com/arunoda/meteor-up/tree/mupx

*
*/


setMeteorRuntime = function(){
  var runConfig, hostname, port, connect, settings, oauth_rootUrl;
  // window.location.origin == "http://localhost:3333"
  switch (window.location.hostname) {
    case 'localhost':
      runConfig = "DEV";
      hostname = window.location.hostname;
      meteorPort = '3333';
      if (window.location.port === meteorPort){
        oauth_rootUrl = connect = window.location.origin;
      } else {
        connect = ['http://', hostname, ':', meteorPort, '/'].join('');
        oauth_rootUrl = ['http://', hostname, ':', '3000', '/'].join('');
      }
      break;
    case 'app.snaphappi.com':
      runConfig = "BROWSER";
      hostname = window.location.hostname
      meteorPort = '3333';
      if (window.location.port === meteorPort){
        oauth_rootUrl = connect = window.location.origin;
      } else {
        connect = ['http://', hostname, ':', meteorPort, '/'].join('');
        oauth_rootUrl = ['http://', hostname, '/macata.App/'].join('');
      }
      break;
    default:
      if (ionic.Platform.isWebView() == false) {
        if (ionic.Platform.isReady) {
          console.error("ERROR: unknown runtime configuration");
          break;
        } else {
          console.warn("WARN: ionic.Platform.isReady not ready?");
        }
      }
      runConfig = "DEVICE";
      hostname = 'app.snaphappi.com';
      port = '3333';
      connect = ['http://', hostname, ':', port, '/'].join('');
      // accounts-facebook-cordova does NOT use oauth redirect_uri
      oauth_rootUrl = '';
      break;
  }

  window.__meteor_runtime_config__ = angular.extend( {}, window.__meteor_runtime_config__, {
    LABEL: runConfig,
    DDP_DEFAULT_CONNECTION_URL: connect
  });

  /**
  *
  default/required Meteor.public.settings for accounts-facebook-cordova
  1. expose Meteor.settings.public on Meteor SERVER as follows:
     Meteor.methods({'settings.public': function(){
       return Meteor.settings.public;
     });

  2. extend on Meteor CLIENT-side by:
    Meteor.call('settings.public', function(err, result) {
    if (err) {
      return;
    }
    Meteor.settings["public"] = _.extend({}, Meteor.settings["public"], result);
    return;
  });

  OR add manually, see setMeteorSettingsPublic() below


  IMPORTANT:
    facebook.oauth_rootUrl sets OAuth._redirectUri(,,,{rootUrl:})
    which MUST point to the client rootUrl requesting loginWithFacebook
    - see: /path/to/meteor/.meteor/local/build/programs/server/packages/facebook.js
  *
  */

  /*
   * add values to Meteor.settings.public on client-side manually
   */
  function setMeteorSettingsPublic(runConfig, oauth_rootUrl) {
    var settings = {
      "public": {
        "label": runConfig,
        "facebook": {
          "oauth_rootUrl": oauth_rootUrl,
          "profileFields": [
            "name",
            "gender",
            "location"
          ]
        }
      }
    };
    window.__meteor_runtime_config__["PUBLIC_SETTINGS"] = settings["public"];
  }

  setMeteorSettingsPublic(runConfig, oauth_rootUrl);

  return
}
setMeteorRuntime();



// meteorServer = ['http://', window.location.hostname, ':3333']
// __meteor_runtime_config__ = {};
// __meteor_runtime_config__.DDP_DEFAULT_CONNECTION_URL = meteorServer.join('');
