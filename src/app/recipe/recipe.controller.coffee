'use strict'

RecipeCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate
  $log, toastr
  appModalSvc, tileHelpers, openGraphSvc
  utils, devConfig, exportDebug
  )->

    vm = this
    vm.title = "Recipes"
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
        newTile: false
        spinner:
          newTile: false
    }

    vm.lookup = {
      colors: ['positive', 'calm', 'balanced', 'energized', 'assertive', 'royal', 'dark', 'stable']
    }


    getData = ()->
      vm.rows = []
      return devConfig.getData()
      .then (data)->
        vm.rows = data
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

      # activate <new-tile>
      createNewTile: ()->
        vm.settings.show.newTile = !vm.settings.show.newTile
        if vm.settings.show.newTile
          # this isn't working
          $timeout ()->document.querySelector('new-tile input').focus()

      forkTile: ($event, item)->
        data = _.pick item, ['url','title','description','image', 'site_name', 'extras']
        # from new-tile.directive fn:_showTileEditorAsModal
        return tileHelpers.modal_showTileEditor(data)
        .then (result)->
          console.log ['forkTile',result]
          return vm.on.submitNewTile(result)
        .then ()->
          item.isOwner = true
        .catch (err)->
          console.warn ['forkTile', err]


      submitNewTile: (result)->
        # new Tile has been submitted to $metor and should be added to collection
        # ?:use a $on listener instead?
        console.log ['submitNewTile', result]
        vm.settings.show.newTile = false

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
      getData()
      return

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
      $log.info "viewLoaded for RecipeCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      # $log.info "viewEnter for RecipeCtrl"
      activate()

    return vm  # end RecipeCtrl


RecipeCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$window', '$timeout'
  '$ionicScrollDelegate'
  '$log', 'toastr'
  'appModalSvc', 'tileHelpers', 'openGraphSvc'
  'utils', 'devConfig', 'exportDebug'
]



###
# @description  RecipeDetailCtrl, controller for directive:list-item-detail
###

RecipeDetailCtrl = (
  $scope, $rootScope, $q
  tileHelpers, openGraphSvc
  $log, toastr
  ) ->
    vm = this
    vm.on = {
      'click': (event, item)->
        event.stopImmediatePropagation()
        $log.info ['RecipeDetailCtrl.on.click', item.name]
        angular.element(
          document.querySelector('.list-item-detail')
        ).toggleClass('slide-under')
        return
      'edit': (event, item)->
        data = _.pick item, ['url','title','description','image', 'site_name', 'extras']
        return tileHelpers.modal_showTileEditor(data)
        .then (result)->
          console.log ["edit", data]
          data.isOwner = true
          return
      'forkTile': ($event, item)->
        data = _.pick item, ['url','title','description','image', 'site_name', 'extras']
        # from new-tile.directive fn:_showTileEditorAsModal
        return tileHelpers.modal_showTileEditor(data)
        .then (result)->
          console.log ['forkTile',result]
          # return vm.on.submitNewTile(result)
        .then ()->
          item.isOwner = true
        .catch (err)->
          console.warn ['forkTile', err]

    }
    console.log ["RecipeDetailCtrl initialized scope.$id=", $scope.$id]
    return vm

RecipeDetailCtrl.$inject = [
  '$scope', '$rootScope', '$q'
  'tileHelpers', 'openGraphSvc'
  '$log', 'toastr'
]


angular.module 'starter.recipe'
  .controller 'RecipeCtrl', RecipeCtrl
  .controller 'RecipeDetailCtrl', RecipeDetailCtrl
