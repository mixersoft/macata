'use strict'

RecipeCtrl = (
  $scope, $rootScope, $q, $location, $window
  $ionicScrollDelegate
  $log, toastr
  appModalSvc, $http
  utils, devConfig, exportDebug
  )->

    # coffeelint: disable=max_line_length
    sampleData = [
      {"og:locale":"en_US","og:title":"Daniel Boulud's Short Ribs Braised in Red Wine with Celery Duo","og:type":"website","og:url":"http://www.epicurious.com/recipes/food/views/daniel-bouluds-short-ribs-braised-in-red-wine-with-celery-duo-106671","og:description":"Chef Boulud says that the success of this dish rests on browning the short ribs well at the beginning of cooking the dish to get the best flavors into the sauce. The Celery Duo starts with a celery root puree and ends with the braised ribs that top the beef. This recipe also can be found in the Café Boulud Cookbook, by Daniel Boulud and Dorie Greenspan.","og:image":"http://www.epicurious.com/static/img/misc/epicurious-social-logo.png","og:site_name":"Epicurious","fb:app_id":"1636080783276430","fb:admins":"14601235","type":"recipe"}
      {"og:locale":"en_US","og:type":"recipe","og:title":"Red Wine-Braised Short Ribs Recipe - Bon Appétit","og:description":"These Red Wine-Braised Short Ribs are even better when they're allowed to sit overnight.","og:url":"http://www.bonappetit.com/recipe/red-wine-braised-short-ribs","og:site_name":"Bon Appétit","article:publisher":"https://www.facebook.com/bonappetitmag","article:tag":"Beef,Dinner,Meat,Ribs","article:section":"Recipes","og:image":"http://www.bonappetit.com/wp-content/uploads/2011/08/red-wine-braised-short-ribs-940x560.jpg","type":"recipe"}
    ]
    # coffeelint: enable=max_line_length

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
    }

    vm.lookup = {
      colors: ['positive', 'calm', 'balanced', 'energized', 'assertive', 'royal', 'dark', 'stable']
    }


    getData = ()->
      if usePromise = true
        vm.rows = []
        $q.when().then ()->
          vm.rows = _.map [0...3], (i)-> return {
            id: i
            color: vm.lookup.colors[i %% vm.lookup.colors.length]
          }
          vm.rows = sampleData.concat(vm.rows)
          console.log "vm.rows set by $q"
          exportDebug.set('rows', vm.rows)
          return vm.rows
      else
        vm.rows = _.map [0...50], (i)-> return {
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

    vm.newCtrl = {
      show: false
      url: 'http://localhost:3333/methods/' + 'get-open-graph'
      data:
        url: null
      new: (ev)->
        vm.newCtrl.show = !vm.newCtrl.show 
        # $ionicScrollDelegate.scrollTo(0,0)
        # TODO: to animate bar into header
        # see https://github.com/djett41/ionic-filter-bar/blob/master/dist/ionic.filter.bar.js

      done: ()->
        self = this
        self.data.url = null
        self.show = false
      createNew: (ev)->
        self = this
        $http.get(self.url, {
          params: self.data
        })
        .then (resp)->
          return $q.reject(resp) if resp.statusText != 'OK'
          return $q.reject('NOT FOUND') if _.isEmpty resp.data
          og = resp.data
          self.createTile(og)
          toastr.info og
          self.done()
          return og
        .catch (err)->
          toastr.warning err
      createTile: (data)->
        data['type'] = 'recipe'
        console.log JSON.stringify data
        vm.rows.unshift(data)
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
  '$scope', '$rootScope', '$q', '$location', '$window'
  '$ionicScrollDelegate'
  '$log', 'toastr'
  'appModalSvc', '$http'
  'utils', 'devConfig', 'exportDebug'
]



###
# @description  RecipeDetailCtrl, controller for directive:list-item-detail
###

RecipeDetailCtrl = (
  $scope, $rootScope, $q
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
    }
    console.log ["RecipeDetailCtrl initialized scope.$id=", $scope.$id]
    return vm

RecipeDetailCtrl.$inject = [
  '$scope', '$rootScope', '$q'
  '$log', 'toastr'
]


angular.module 'starter.recipe'
  .controller 'RecipeCtrl', RecipeCtrl
  .controller 'RecipeDetailCtrl', RecipeDetailCtrl







