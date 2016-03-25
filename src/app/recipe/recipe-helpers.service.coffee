'use strict'

RecipeHelpers = (
  $timeout, utils, tileHelpers, AAAHelpers
)->
  class RecipeHelpersClass
    constructor: (@context)->
      return if !@context
      utils.bindInstanceMethods @, @context
      return

    favorite: ($event, model)->
      self = @
      return AAAHelpers.requireUser('sign-in')
      .then ()->
        # return mcFeeds.helpers.toggleLike(model)
        self.call 'Recipe.toggleFavorite', model, (err, result)->
          console.warn ['Meteor::toggleFavorite WARN', err] if err
          console.log ['Meteor::toggleFavorite OK']

    edit: (event, item)->
      data = _.pick item, ['url','title','description','image', 'site_name', 'extras']
      return tileHelpers.modal_showTileEditor(data)
      .then (result)->
        console.log ["edit", data]
        data.isOwner = true
        return

    forkTile: ($event, item)->
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


  return RecipeHelpersClass

RecipeHelpers.$inject = ['$timeout', 'utils', 'tileHelpers', 'AAAHelpers']

angular.module 'starter.recipe'
  .factory 'RecipeHelpers', RecipeHelpers
