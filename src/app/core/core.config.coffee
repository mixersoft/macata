'use strict'

appRun = ($ionicPlatform, $ionicHistory, $rootScope, $location
  deviceReady
  $log, devConfig, AAAHelpers
) ->

  # devConfig.loadData()

  Meteor.call('settings.public', (err,result)->
    return if err
    Meteor.settings.public = _.extend {}, Meteor.settings.public, result
    console.info ['Meteor.settings.public', Meteor.settings.public]
    )

  $rootScope['loadOnce'] = []

  $rootScope.user = Meteor.user()
  AAAHelpers._backwardCompatibleMeteorUser($rootScope.user)

  deviceReady.waitP().then ()->
    # Hide the accessory bar by default (remove this to show the accessory bar above the keyboard
    # for form inputs)
    if window.cordova and window.cordova.plugins and window.cordova.plugins.Keyboard
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar true

    if window.StatusBar
      # org.apache.cordova.statusbar required
      StatusBar.styleLightContent()

    $rootScope.goBack = (noBackTarget = 'app.home')->
      if $ionicHistory.backView()
        $ionicHistory.goBack()
      else
        $state.transitionTo(noBackTarget)
      return

    locationSearch = null
    $rootScope.$on '$stateChangeStart', (ev, toState, toParams, fromState, fromParams)->
      # save $location.search and add back after transition
      locationSearch = $location.search()

      # check if state requires user to signIn, see *.route.coffee
      requireLogin = toState.data?.requireLogin
      if requireLogin
        $log.warn "call signInRegisterSvc.showSignInRegister('signin')"

      return

    $rootScope.$on '$stateChangeSuccess', (ev, toState, toParams, fromState, fromParams)->
      # addback $location.search  after transition
      # $location.search( angular.extend(locationSearch, $location.search()) )
      return

  return # appRun


appRun.$inject = [
  '$ionicPlatform', '$ionicHistory', '$rootScope', '$location',
  'deviceReady'
  '$log', 'devConfig', 'AAAHelpers'
]

toastrConfig = (toastrConfig) ->
  angular.extend toastrConfig, {
    timeOut: 4000
    positionClass: 'toast-bottom-left'
  }

toastrConfig.$inject = ['toastrConfig']

ionicConfig = ($ionicConfigProvider)->
  $ionicConfigProvider.backButton.text('')
  $ionicConfigProvider.backButton.previousTitleText(false)
  $ionicConfigProvider.views.forwardCache(true)
  $ionicConfigProvider.scrolling.jsScrolling(false)
  return

ionicConfig.$inject = ['$ionicConfigProvider']






angular
  .module 'starter.core'
  .config toastrConfig
  .config ionicConfig
  .run appRun
