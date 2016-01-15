'use strict'

EventDetailCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate
  $log, toastr
  appModalSvc, tileHelpers, openGraphSvc
  utils, devConfig, exportDebug
  )->

    viewLoaded = null   # promise

    vm = this
    vm.title = "Event Detail"
    vm.me = null      # current user, set in initialize()
    vm.acl = {
      isVisitor: ()->
        return true if !$rootScope.user
      isUser: ()->
        return true if $rootScope.user
    }
    vm.settings = {
      view:
        show: 'grid'
        'new': false
      show:
        'expandEventDetails': false
    }

    vm.lookup = {}

    vm.event = {
      menuItems: []
    }

    getData = ()->
      vm.event.menuItems = []
      return devConfig.getData()
      .then (data)->
        vm.event.menuItems = _.chain data
          .reduce (result, o, i)->
            if ~[0,1,4].indexOf(i)
              o.id = i
              result.push o
            return result
          , []
          .value()
        return vm.event.menuItems

    vm.on = {
      scrollTo: (anchor)->
        $location.hash(anchor)
        $ionicScrollDelegate.anchorScroll(true)
        return

      setView: (value)->
        if 'value==null'
          next = if vm.settings.show == 'grid' then 'list' else 'grid'
          return vm.settings.view.show = next
        return vm.settings.view.show = value

    }

    initialize = ()->
      return viewLoaded = $q.when()
      .then ()->
        if $rootScope.user?
          vm.me = $rootScope.user
        else
          DEV_USER_ID = '0'
          devConfig.loginUser( DEV_USER_ID ).then (user)->
            # loginUser() sets $rootScope.user
            vm.me = $rootScope.user
            toastr.info "Login as userId=0"
            return vm.me
      .then ()->
        getData()

    activate = ()->
      # // Set Ink
      ionic.material?.ink.displayEffect()
      ionic.material?.motion.fadeSlideInRight({
        startVelocity: 2000
        })
      return

    resetMaterialMotion = (motion, parentId)->
      className = {
        'fadeSlideInRight': '.animate-fade-slide-in-right'
        'blinds': '.animate-blinds'
        'ripple': '.animate-ripple'
      }
      selector = '{aniClass} .item'.replace('{aniClass}', className[motion] )
      selector = '#'+ parentId + ' ' + selector if parentId?
      angular.element(document.querySelectorAll(selector))
        .removeClass('in')
        .removeClass('done')

    $scope.$on '$ionicView.leave', (e) ->
      resetMaterialMotion('fadeSlideInRight')

    $scope.$on '$ionicView.loaded', (e)->
      $log.info "viewLoaded for EventDetailCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      # $log.info "viewEnter for EventDetailCtrl"
      activate()

    return vm  # end EventDetailCtrl


EventDetailCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$window', '$timeout'
  '$ionicScrollDelegate'
  '$log', 'toastr'
  'appModalSvc', 'tileHelpers', 'openGraphSvc'
  'utils', 'devConfig', 'exportDebug'
]


angular.module 'starter.events'
  .controller 'EventDetailCtrl', EventDetailCtrl
