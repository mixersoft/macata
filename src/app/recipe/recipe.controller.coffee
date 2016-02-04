'use strict'

RecipeCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate, $state, $stateParams, $listItemDelegate
  $log, toastr
  appModalSvc, tileHelpers, openGraphSvc, IdeasResource
  utils, devConfig, exportDebug
  )->

    viewLoaded = null   # promise

    vm = this
    vm.title = "Ideas"
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

    vm.lookup = {
      colors: ['positive', 'calm', 'balanced', 'energized', 'assertive', 'royal', 'dark', 'stable']
    }

    getData = ()->
      vm.rows = []
      return IdeasResource.query()
      .then (data)->
        vm.rows = data
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

      #  list-item-container[on-select]
      select: ($item, $index, silent)->
        # update history url
        $state.transitionTo($state.current.name
        , {id: $item && $item.id || $index || null}
        , {notify:false}
        )
        return if silent

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


      # called by <new-tile[on-complete]>
      submitNewTile: (result)->
        # new Tile has been submitted to $metor and should be added to collection
        # ?:use a $on listener instead?
        console.log ['submitNewTile', result]
        vm.settings.show.newTile = false
        # console.log "newTile=" + JSON.stringify result
        # check result.body for details
        if result
          return IdeasResource.post(result)
          .then ()->
            return IdeasResource.query()
          .then (result)->
            vm.rows = result


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
        vm.listItemDelegate = $listItemDelegate.getByHandle('recipe-list-scroll')
      .then ()->
        return getData()

    activate = ()->
      if index = $stateParams.id
        vm.listItemDelegate.select(null, vm.rows[index], index)
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
      $log.info "viewEnter for RecipeCtrl"
      return viewLoaded.finally ()->
        activate()

    return vm  # end RecipeCtrl


RecipeCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$window', '$timeout'
  '$ionicScrollDelegate', '$state', '$stateParams', '$listItemDelegate'
  '$log', 'toastr'
  'appModalSvc', 'tileHelpers', 'openGraphSvc', 'IdeasResource'
  'utils', 'devConfig', 'exportDebug'
]



###
# @description  RecipeDetailCtrl, controller for directive:list-item-detail
###

RecipeDetailCtrl = (
  $scope, $rootScope, $q, $state
  tileHelpers, openGraphSvc
  $log, toastr
  ) ->
    vm = this
    vm.on = {
      'gotoTarget':(event, item)->
        event.stopImmediatePropagation()
        switch item.className
          when 'Events'
            return $state.go('app.event-detail', {id:item.id})
            # return "app.events({id:'" + item.id + "'})"
          else
            return  $state.go('app.recipe', {id:item.id})
            # return "app.recipe({id:'" + item.id + "'})"


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
  '$scope', '$rootScope', '$q', '$state'
  'tileHelpers', 'openGraphSvc'
  '$log', 'toastr'
]


###
# @description  RecipeSearchCtrl, controller for search/filter recipe modal
###

RecipeSearchCtrl = (
  $scope, $rootScope, $q
  tileHelpers, $listItemDelegate, devConfig
  $log, toastr
  ) ->
    mm = this
    mm.name = "RecipeSearchCtrl"
    mm.selectedItem = null
    mm.afterModalShow = (modal)->
      # params from appModalSvc.show( template , controllerAs , params, options) available
      # mm = copyToModalViewModal = {
      #   rows: vm.rows
      # }
      angular.extend mm, $scope.copyToModalViewModal

      # other init methods
      mm.listItemDelegate = $listItemDelegate.getByHandle('recipe-search-list-scroll')
      mm.listItemDelegate.favorite = mm.on.favorite
    mm.on = {
      'use': ()->
        selected = mm.listItemDelegate.selected()
        mm.closeModal selected
      'favorite': (event, item)->
        event.stopImmediatePropagation()
        item.favorite = !item.favorite
        $log.info ['RecipeSearchCtrl.on.favorite', item.title]
        return
      'select': (item, index, silent)->
        event.stopImmediatePropagation()
        $log.info ['RecipeSearchCtrl.on.select', item.title]
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
          # return mm.on.submitNewTile(result)
        .then ()->
          item.isOwner = true
        .catch (err)->
          console.warn ['forkTile', err]

    }

    once = $scope.$on 'modal.afterShow', (ev, modal)->
      once?()
      if modal == $scope.modal
        mm.afterModalShow()
      return

    console.log ["RecipeSearchCtrl initialized scope.$id=", $scope.$id]
    return mm

RecipeSearchCtrl.$inject = [
  '$scope', '$rootScope', '$q'
  'tileHelpers', '$listItemDelegate', 'devConfig'
  '$log', 'toastr'
]

angular.module 'starter.recipe'
  .controller 'RecipeCtrl', RecipeCtrl
  .controller 'RecipeDetailCtrl', RecipeDetailCtrl
  .controller 'RecipeSearchCtrl', RecipeSearchCtrl
