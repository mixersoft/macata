'use strict'

GridCtrl = (
  $scope, $rootScope, $q, $location, $window
  $ionicScrollDelegate
  $log, toastr
  appModalSvc
  utils, devConfig, exportDebug
  )->

    vm = this
    vm.title = "Grid"
    vm.me = null      # current user, set in initialize()

    vm.settings = {
      view:
        show: 'grid'
    }

    vm.lookup = {
      colors: ['positive', 'calm', 'balanced', 'energized', 'assertive', 'royal', 'dark', 'stable']
    }


    if usePromise = true
      vm.rows = []
      $q.when().then ()->
        vm.rows = _.map [0..50], (i)-> return {
          id: i
          color: vm.lookup.colors[i %% vm.lookup.colors.length]
        }
        console.log "vm.rows set by $q"
        return vm.rows
    else
      vm.rows = _.map [0..50], (i)-> return {
        id: i
        color: vm.lookup.colors[i %% vm.lookup.colors.length]
      }

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
      # return
      if $rootScope.user?
        vm.me = $rootScope.user
      else
        DEV_USER_ID = '0'
        devConfig.loginUser( DEV_USER_ID ).then (user)->
          # loginUser() sets $rootScope.user
          vm.me = $rootScope.user
          toastr.info "Login as userId=0"
          return vm.me

    activate = ()->
      return

    $scope.$on '$ionicView.loaded', (e)->
      $log.info "viewLoaded for GridCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      # $log.info "viewEnter for GridCtrl"
      activate()

    return vm  # end GridCtrl


GridCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$window'
  '$ionicScrollDelegate'
  '$log', 'toastr'
  'appModalSvc'
  'utils', 'devConfig', 'exportDebug'
]



###
# @description  ItemDetailCtrl, controller for directive:list-item-detail
###

ItemDetailCtrl = (
  $scope, $rootScope, $q
  $log, toastr
  ) ->
    vm = this
    vm.on = {
      'click': (event, item)->
        event.stopImmediatePropagation()
        $log.info ['ItemDetailCtrl.on.click', item.name]
        angular.element(
          document.querySelector('.list-item-detail')
        ).toggleClass('slide-under')
        return
    }
    console.log ["ItemDetailCtrl initialized scope.$id=", $scope.$id]
    return vm

ItemDetailCtrl.$inject = [
  '$scope', '$rootScope', '$q'
  '$log', 'toastr'
]


angular.module 'starter.grid'
  .controller 'GridCtrl', GridCtrl
  .controller 'ItemDetailCtrl', ItemDetailCtrl
