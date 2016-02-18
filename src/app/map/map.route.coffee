'use strict'

appRun = (routerHelper) ->
  routerHelper.configureStates getStates()

getStates = ->
  [
    state: 'app.map'
    config:
      cache: true
      url: '/map?id'
      views:
        'menuContent':
          templateUrl: 'map/map.html'
          controller: 'MapCtrl as vm'
  ]

appRun.$inject = ['routerHelper']

angular
  .module 'starter.map'
  .run appRun
