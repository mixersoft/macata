'use strict'
global = @

bootstrap = ()->
  # angular.bootstrap ['macata.server']

  # from package erasaur:meteor-lodash
  global._ = lodash
  console.log(['lodash.VERSION=', global._.VERSION, lodash.VERSION])

  # accounts-facebook
  ServiceConfiguration.configurations.remove({
    service: "facebook"
  })
  ServiceConfiguration.configurations.upsert({
    service: "facebook"
  }, {
    $set: {
      appId: Meteor.settings.facebook.appId,
      loginStyle: "popup",
      secret: Meteor.settings.facebook.secret
    }
  })
  fbConfig = ServiceConfiguration.configurations.findOne({service:'facebook'})
  console.log ['facebook.clientId=', fbConfig.appId]

  # oauthProxy
  # // Listen to incoming HTTP requests, can only be used on the server
  WebApp.rawConnectHandlers.use("/_oauth", (req, res, next)->
    res.setHeader("Access-Control-Allow-Origin", "*")
    return next()
  )

  return

Meteor.startup(bootstrap)
