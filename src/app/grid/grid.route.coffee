'use strict'

appRun = (routerHelper) ->
  routerHelper.configureStates getStates()

getStates = ->
  [
    state: 'app.grid'
    config:
      url: '/grid'
      views:
        'menuContent':
          templateUrl: 'grid/grid.html'
          controller: 'GridCtrl as vm'
  ]

appRun.$inject = ['routerHelper']

angular
  .module 'starter.grid'
  .run appRun
