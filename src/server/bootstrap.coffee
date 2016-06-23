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

    'deploy.getChannel': (deviceId)->
      DEFAULT_CHANNEL_TAG = 'dev'
      user = Meteor.user()
      # keep device or user on the SAME channel?
      # user.devices = [{deviceId:XXX, channelTag: YYY}]
      return DEFAULT_CHANNEL_TAG if !user

      found = _.find user.devices, {deviceId: deviceId}
      channelTag = found?.channelTag || DEFAULT_CHANNEL_TAG
      if !found
        modifier = {'$addToSet':
          'devices': {deviceId:deviceId, channelTag:channelTag}
        }
        Meteor.users.update({_id: user._id}, modifier)
      console.info ['ionicDeploy=', deviceId, channelTag]
      return channelTag

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

  # see also: Meteor.settings.public.facebook.oauth_rootUrl


  # override to allow oauth redirect from local domain
  Package.oauth.OAuth._checkRedirectUrlOrigin = (redirectUrl)->
    appHost = Meteor.settings.public?.facebook?.oauth_rootUrl
    appHost = Meteor.absoluteUrl() if !appHost
    # console.log [
    #   "Accounts.oauth._checkRedirectUrlOrigin",
    #   "appHost=" + appHost,
    #   "redirectUrl=" + redirectUrl
    # ]
    appHostReplacedLocalhost = Meteor.absoluteUrl(undefined, {
      replaceLocalhost: true
    })
    return (
      redirectUrl.substr(0, appHost.length) != appHost &&
      redirectUrl.substr(0, appHostReplacedLocalhost.length) != appHostReplacedLocalhost
    )

  # redirect to '/public/index.html'
  # see: http://stackoverflow.com/questions/37901200/how-can-i-fs-readfile-a-file-from-the-public-folder-of-a-meteor-up-deployment
  ## using IronRouter
  # cd ./meteor/private; ln -s ../public/index.html .
  defaultRouteIronRouter = ()->
    Router.route( '/', { where: 'server' } )
    .get ()->
      contents = Assets.getText('index.html')
      this.response.end contents


  ## using WebApp.connectHandlers
  defaultRouteConnect = ()->
    fs = Npm.require('fs')
    crypto = Npm.require('crypto')

    search = [
      '../../programs/web.browser/app/index.html' # mupx location
      process.env.PWD + '/public/index.html'      # meteor project location
    ]

    _redirect = (filepath, req, res)->
      ## serve default file, with eTag
      # console.log 'bootstrap.js: filepath=' + filepath
      fs.readFile(filepath, (err, buf)->
        if err
          res.writeHead(500, 'Error reading index.html' )
          return res.end()

        try
          eTag = crypto.createHash('md5').update(buf).digest('hex')
          # console.log 'bootstrap.js: eTag=' + eTag
          if req.headers['if-none-match'] == eTag
            res.writeHead(304, 'Not Modified' )
            return res.end()
        catch err
          eTag = Date.now()

        headers = {
          'Content-Type': 'text/html'
          'ETag': eTag
        }
        console.log headers
        res.writeHead(200, headers)
        return res.end(buf)
      )

    WebApp.connectHandlers.use("/", (req, res, next)->
      return next() if req.originalUrl != '/'
      return next() if req.method != 'GET'

      found = _.some search, (filepath)->
        try
          if fs.statSync(filepath).isFile()
            _redirect(filepath, req, res)
            return true
        catch err
        return false

      if found == false
        console.log "index.html file not available, seach=", search
        result = fs.readdirSync('.')
        console.log result
        res.writeHead(500, 'Default index.html Not Found' )
        return res.end()

      return
    )

  if useIronRouter = false
    defaultRouteIronRouter()
  else
    defaultRouteConnect()

  console.log("Settings=" + JSON.stringify(Meteor.settings))

  return

Meteor.startup(bootstrap)
