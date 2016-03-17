'use strict'

appRun = (routerHelper) ->
  routerHelper.configureStates getStates()

getStates = ->
  [
    state: 'app.feed'
    config:
      cache: true
      url: '/feed/:id'
      views:
        'menuContent':
          templateUrl: 'feed/feed-wrap.html'
          controller: 'FeedCtrl as vm'
  ]

appRun.$inject = ['routerHelper']

angular
  .module 'starter.feed'
  .run appRun
