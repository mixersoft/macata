# Ionic Starter App

# angular.module is a global place for creating, registering and retrieving Angular modules
# 'starter' is the name of this angular module example (also set in a <body> attribute in index.html)
# the 2nd parameter is an array of 'requires'
# 'starter.services' is found in services.js
# 'starter.controllers' is found in controllers.js

'use strict'

angular
  .module 'macata.server', [
    'angular-meteor'
    'macata.services'
    'macata.data'
  ]


ServerConfig = (ServerAPIProvider)->
  ServerAPIProvider.register('UsersResource')
  ServerAPIProvider.register('EventsResource')
  return
ServerConfig.$inject = ['ServerAPIProvider']




AppRun = ($log)->
  $log.info('macata.server AppRun')
  return
AppRun.$inject = ['$log']



angular
  .module 'macata.server'
  .config ServerConfig
  .run AppRun
