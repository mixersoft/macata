'use strict'

angular
  .module 'oauth', ['ionic']


OauthProxy = (
  $http
  )->
    config = {
      rootUrl: __meteor_runtime_config__.DDP_DEFAULT_CONNECTION_URL
      path: location.pathname.slice(location.pathname.indexOf('_oauth'))
    }
    self = {
      getFromServer: (options = {})->
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

OauthResponse = (
  oauthProxy
  )->
    return self = {
      handleByLoginStyle: ()->
        console.log('href=' + window.location.href)
        oauthProxy.getFromServer()
        .then (result)->
          return console.warn ['Status', result.status] if result.status != 200
          result = result.data.match(/({.*})/).pop()
          return result
        , (err)->
          console.warn err
        .then (result)->
          config = JSON.parse result
          console.log ['config=', config]

          loginStyle = if config.redirectUrl? then 'redirect' else 'popup'
          switch loginStyle
            when 'redirect'
              return self.handleRedirect(config)
            when 'popup'
              return self.handlePopup(config)

      handlePopup: (config)->
        # document.getElementById("config").innerHTML = JSON.stringify config
        oauthProxy.doOauthRedirect(config)

      handleRedirect: (config)->
        if not config.setCredentialToken
          return console.warn [
            'loginWithFacebook() style=redirect'
            'Server not returning config.credentialSecret correctly'
            config
          ]
        key = config.storagePrefix + config.credentialToken
        sessionStorage[key] = config.credentialSecret
        # why is this getting encoded twice, proxy?
        redirectUrl = config.redirectUrl.replace(/&#x2F;/g,'/')
        console.log ['redirectUrl', redirectUrl]
        window.location = redirectUrl

    }


OauthResponse.$inject = ['oauthProxy']


appRun = (oauthResponse)->
  oauthResponse.handleByLoginStyle()
  return


appRun.$inject = ['oauthResponse']

angular.module 'oauth'
  .factory 'oauthProxy', OauthProxy
  .factory 'oauthResponse', OauthResponse
  .run appRun
