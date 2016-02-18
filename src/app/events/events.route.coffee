'use strict'

appRun = (routerHelper) ->
  routerHelper.configureStates getStates()

getStates = ->
  [
    state: 'app.events'
    config:
      cache: true
      url: '/events/:filter'
      views:
        'menuContent':
          templateUrl: 'events/events.html'
          controller: 'EventCtrl as vm'
  ,
    state: 'app.event-detail'
    config:
      cache: true
      url: '/event-detail/:id'
      views:
        'menuContent':
          templateUrl: 'events/event-detail.html'
          controller: 'EventDetailCtrl as vm'
  ,
    state: 'app.event-detail.invitation'
    config:
      url: '^/app/invitation/:invitation'
      views:
        'menuContent':
          templateUrl: 'events/events.html'
          controller: 'EventDetailCtrl as vm'
  ]

appRun.$inject = ['routerHelper']

angular
  .module 'starter.events'
  .run appRun
