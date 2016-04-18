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

    vm.pullToReveal = {
      options:
        initialSlide: 0
        pagination: false
      slider: null
      slide: (name)->
        self = vm.pullToReveal
        switch name
          # when 'setLocation'
          #   self.slider.slideTo(0)
          when 'searchSort'
            self.slider.slideTo(0)
            selector = '#' + vm.viewId + ' input'
            setTimeout ()->return document.querySelector(selector ).focus()
            return
          when 'newTile'
            self.slider.slideTo(2)
            selector = '#' + vm.viewId + ' new-tile input'
            setTimeout ()->return document.querySelector(selector ).focus()
            return
          when 'default'
            self.slider.slideTo(self.options.initialSlide)
    }
    vm.settings = {
      view:
        show: 'grid'
        'new': false
      show:
        pullToReveal: false
    }

    vm.filterSort = {
      label: null
      defaultFilterBy: {}
      filterBy: {}
      sortBy: {
        "title":1
      }
      page: 1
      perpage: 20
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
      overscrollReveal: (show)->
        # if !location = locationHelpers.lastKnownLonLat()
        #   return vm.pullToReveal.slide('setLocation')
        return vm.pullToReveal.slide('searchSort')

      filterBy: ($ev, value)->
        baseFilter = vm.filterSort
        if !value
          vm.filterSort.filterBy = vm.filterSort.defaultFilterBy
          return
        match = _.map value.split(' '), (word)->
          return "(?=.*" + word + ")"
        match = match.join('')
        baseFilter.filterBy = {
          $and:[
            baseFilter.defaultFilterBy
            $or: [
              { title: {$regex: match, $options: 'i'} }
              { description: {$regex: match, $options: 'i'} }
            ]
          ]
        }

        exportDebug.set('filter', vm.filterSort)
        return

      # activate <new-tile>
      createNewTile: ()->
        # vm.filterSort.sortBy.title = -1 * vm.filterSort.sortBy.title
        # return
        return AAAHelpers.requireUser('sign-in')
        .then (me)->
          vm.settings.show.pullToReveal = !vm.settings.show.pullToReveal
          if vm.settings.show.pullToReveal
            vm.pullToReveal.slide('newTile')

      'forkTile': vm.recipeHelpers['forkTile']
      'edit': vm.recipeHelpers['edit']
      'favorite': vm.recipeHelpers['favorite']


      # called by <new-tile[on-complete]>
      submitNewTile: (result)->
        return AAAHelpers.requireUser('sign-in')
        .then (me)->
          # post to Meteor
          vm.call 'Recipe.insert', result, (err, result)->
            console.warn ['Meteor::insert WARN', err] if err
            return if !result || result.errorType == 'Meteor.Error'
            console.log ['Meteor::insert OK']
            console.log ['submitNewTile', result]
            vm.settings.show.newTile = false
            $timeout(50).then ()->
              vm.selectedItemId = result
              data = mcRecipes.findOne(vm.selectedItemId)
              vm.on.select(data, null, 'silent')
    }

    getAsPublishSpec = (filterSort)->
      return [
        filterSort.filterBy
        {
          limit: parseInt(filterSort.perpage)
          skip: parseInt( (filterSort.page - 1) * filterSort.perpage )
          sort: filterSort.sortBy
        }
      ]

    initialize = ()->

      vm.subscribe 'myVisibleRecipes'
      ,()->
        return getAsPublishSpec( vm.getReactively('filterSort', true) )

      vm.helpers {
        'rows': ()->
          return mcRecipes.find(
            vm.getReactively('filterSort.filterBy')
            ,{
              sort: vm.getReactively('filterSort.sortBy', true)
            })
      }
      vm.autorun ()->
        filterSort = vm.getReactively('filterSort', true)
        console.log ['sortBy', JSON.stringify filterSort.sortBy]
        vm.title = filterSort.label
        return

      exportDebug.set('vm', vm)
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
# @description  RecipeSearchCtrl, controller for search/filter recipe modal
#   when attaching Recipe from directive:newTile
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
