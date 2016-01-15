'use strict'

appRun = (routerHelper) ->
  routerHelper.configureStates getStates()

getStates = ->
  [
    state: 'app.recipe'
    config:
      url: '/recipe?id'
      views:
        'menuContent':
          templateUrl: 'recipe/recipe.html'
          controller: 'RecipeCtrl as vm'
  ]

appRun.$inject = ['routerHelper']

angular
  .module 'starter.recipe'
  .run appRun
