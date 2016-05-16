'use strict'
global = @

bootstrap = ()->
  # angular.bootstrap ['macata.server']

  # from package erasaur:meteor-lodash
  global._ = lodash
  console.log(['lodash.VERSION=', global._.VERSION, lodash.VERSION])

  # meteor-client-side: load Meteor.settings.public
  Meteor.methods( {
    'settings.public': ()->
      return if Meteor.isClient
      return Meteor.settings.public
    }
  )

  # accounts-facebook
  ServiceConfiguration.configurations.remove({
    service: "facebook"
  })
  ServiceConfiguration.configurations.upsert({
    service: "facebook"
  }, {
    $set: {
      appId: Meteor.settings.facebook.appId,
      secret: Meteor.settings.facebook.secret,
      loginStyle: "popup"
      # loginStyle: "redirect"
    }
  })
  fbConfig = ServiceConfiguration.configurations.findOne({service:'facebook'})
  # console.log ['facebook.clientId=', fbConfig.appId]

  # oauthProxy
  # // Listen to incoming HTTP requests, can only be used on the server
  WebApp.rawConnectHandlers.use("/_oauth", (req, res, next)->
    res.setHeader("Access-Control-Allow-Origin", "*")
    return next()
  )

  # see also: Meteor.settings.facebook.oauth_redirect_uri

  console.log("Settings=" + JSON.stringify(Meteor.settings))

  return

Meteor.startup(bootstrap)
