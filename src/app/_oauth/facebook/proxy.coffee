'use strict'

angular
  .module 'oauth', ['ionic']


OauthProxy = (
  $http
  )->
    config = {
      rootUrl: 'http://localhost:3333'
      path: location.pathname
    }
    self = {
      get: (options = {})->
        options =  angular.copy config, options
        url = [
          options.rootUrl
          options.path
          location.search
        ].join('')
        console.log('proxy=' + url)
        return $http.get(url)
      doOauthRedirect: (config)->
        if config.setCredentialToken
          credentialToken = config.credentialToken
          credentialSecret = config.credentialSecret

          if config.isCordova
            credentialString = JSON.stringify {
              credentialToken: credentialToken
              credentialSecret: credentialSecret
            }
            window.location.hash = credentialString

          if (window.opener && window.opener.Package &&
                window.opener.Package.oauth)
            window.opener.Package.oauth.OAuth._handleCredentialSecret(
              credentialToken, credentialSecret)
          else
            try
              localStorage[config.storagePrefix + credentialToken] = credentialSecret
            catch err
              angular.noop
        if not config.isCordova
          document.getElementById("completedText").style.display = "block"
          document.getElementById("loginCompleted").onclick = ()->
            window.close()
          window.close()
        return

    }
    return self

OauthProxy.$inject = ['$http']

appRun = (oauthProxy)->
  console.log('href=' + window.location.href)
  oauthProxy.get()
  .then (result)->
    return console.warn ['Status', result.status] if result.status != 200
    credentials = result.data.match(/({.*})/).pop()
    return credentials
  , (err)->
    console.warn err
  .then (credentials)->
    document.getElementById("config").innerHTML = credentials
    config = JSON.parse credentials
    console.log 'config=' + credentials
    oauthProxy.doOauthRedirect(config)


appRun.$inject = ['oauthProxy']

angular.module 'oauth'
  .factory 'oauthProxy', OauthProxy
  .run appRun
