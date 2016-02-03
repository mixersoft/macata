'use strict'

EventCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate, $state, $stateParams, $listItemDelegate
  $log, toastr
  appModalSvc, tileHelpers, openGraphSvc
  utils, devConfig, exportDebug
  )->

    viewLoaded = null   # promise

    vm = this
    vm.title = "Events"
    vm.me = null      # current user, set in initialize()
    vm.listItemDelegate = null
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
        newTile: false
        spinner:
          newTile: false
    }

    vm.lookup = {}


    getData = ()->
      vm.rows = []
      return devConfig.getData(null,{className:'Event'})
      .then (data)->
        vm.rows = _.filter data, (o,i,l)->
          return true if ~[0,1,4].indexOf(i)
        exportDebug.set('rows', vm.rows)
        return vm.rows

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
        vm.listItemDelegate = $listItemDelegate.getByHandle('events-list-scroll')
      .then ()->
        getData()

    activate = ()->
      if index = $stateParams.filter
        console.warn 'TODO: set filter on viewEnter'
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
      $log.info "viewLoaded for EventCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      # $log.info "viewEnter for EventCtrl"
      return viewLoaded.finally ()->
        activate()

    return vm  # end EventCtrl


EventCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$window', '$timeout'
  '$ionicScrollDelegate', '$state', '$stateParams', '$listItemDelegate'
  '$log', 'toastr'
  'appModalSvc', 'tileHelpers', 'openGraphSvc'
  'utils', 'devConfig', 'exportDebug'
]





angular.module 'starter.events'
  .controller 'EventCtrl', EventCtrl
