'use strict'

RecipeCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate, $state, $stateParams, $listItemDelegate
  $log, toastr
  appModalSvc, tileHelpers, openGraphSvc, AAAHelpers
  $reactive
  CollectionHelpers, RecipeHelpers
  utils, devConfig, exportDebug
  )->
    # add angular-meteor reactivity
    $reactive(this).attach($scope)
    global = $window
    vm = this

    vm.title = "Ideas"
    vm.viewId = ["recipe-view",$scope.$id].join('-')

    vm.recipeHelpers = new RecipeHelpers(vm)
    vm.collHelpers = new CollectionHelpers(vm)
    vm.listItemDelegate = null
    vm.RecipeM = RecipeModel::

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
        return AAAHelpers.requireUser('sign-in')
        .then (me)->
          vm.settings.show.newTile = !vm.settings.show.newTile
          if vm.settings.show.newTile
            # this isn't working
            $timeout ()->document.querySelector('new-tile input').focus()

      'forkTile': vm.recipeHelpers['forkTile']
      'edit': vm.recipeHelpers['edit']
      'favorite': vm.recipeHelpers['favorite']


      # called by <new-tile[on-complete]>
      submitNewTile: (result)->
        return AAAHelpers.requireUser('sign-in')
        .then (me)->
          # new Tile has been submitted to $metor and should be added to collection
          # ?:use a $on listener instead?
          console.log ['submitNewTile', result]
          vm.settings.show.newTile = false
          # console.log "newTile=" + JSON.stringify result
          # check result.body for details
          if result
            result.ownerId = me._id
            mcRecipes.insert(result)
            return


    }

    initialize = ()->


      vm.subscribe 'myVisibleRecipes'
      ,()->
        filterBy = null
        paginate = null
        return subscription = [ filterBy, paginate  ]

      vm.helpers {
        'rows': ()->
          mcRecipes.find({})
      }
      return

    activate = ()->
      vm.listItemDelegate = $listItemDelegate.getByHandle('recipe-list-scroll', $scope)
      return $q.when()
      .then ()->
        # // Set Ink
        ionic.material?.ink.displayEffect()
        ionic.material?.motion.fadeSlideInRight({
          startVelocity: 2000
          })
        return
      .then ()->
        if index = $stateParams.id
          $timeout(0).then ()->
            vm.listItemDelegate.select(null, vm.rows[index], index)

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
      # $log.info "viewLoaded for RecipeCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      $log.info "viewEnter for RecipeCtrl"
      activate()

    return vm  # end RecipeCtrl


RecipeCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$window', '$timeout'
  '$ionicScrollDelegate', '$state', '$stateParams', '$listItemDelegate'
  '$log', 'toastr'
  'appModalSvc', 'tileHelpers', 'openGraphSvc', 'AAAHelpers'
  '$reactive'
  'CollectionHelpers', 'RecipeHelpers'
  'utils', 'devConfig', 'exportDebug'
]





###
# @description  RecipeDetailCtrl, controller for directive:list-item-detail
###

RecipeDetailCtrl = (
  $scope, $rootScope, $q, $state
  tileHelpers, openGraphSvc, RecipeHelpers
  $log, toastr
  ) ->
    vm = this
    vm.recipeHelpers = new RecipeHelpers(vm)
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

      'forkTile': vm.recipeHelpers['forkTile']
      'edit': vm.recipeHelpers['edit']

    }
    console.log ["RecipeDetailCtrl initialized scope.$id=", $scope.$id]
    return vm

RecipeDetailCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$state'
  'tileHelpers', 'openGraphSvc', 'RecipeHelpers'
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
  # .factory 'RecipeHelpers', RecipeHelpers
  .controller 'RecipeCtrl', RecipeCtrl
  .controller 'RecipeDetailCtrl', RecipeDetailCtrl
  .controller 'RecipeSearchCtrl', RecipeSearchCtrl
