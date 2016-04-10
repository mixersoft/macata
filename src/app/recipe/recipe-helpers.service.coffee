'use strict'

RecipeHelpers = (
  $q, $timeout, utils, tileHelpers, AAAHelpers
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
      self = @
      return AAAHelpers.requireUser('sign-in')
      .then (me)->
        return $q.reject("WARN: no permission to edit") if item.ownerId != me._id
        data = _.pick item, ['url','title','description','image', 'site_name', 'extras']
        return tileHelpers.modal_showTileEditor(data)
        .then (result)->
          # post to Meteor
          angular.extend result, _.pick(item, ['_id','className','ownerId'])
          self.call 'Recipe.update', result, (err, result)->
            console.warn ['Meteor::edit WARN', err] if err
            console.log ['Meteor::edit OK']
          return

    forkTile: ($event, item)->
      self = @
      return AAAHelpers.requireUser('sign-in')
      .then (me)->
        data = _.pick item, ['url','title','description','image', 'site_name', 'extras']
        # from new-tile.directive fn:_showTileEditorAsModal
        return tileHelpers.modal_showTileEditor(data)
        .then (result)->
          # post to Meteor
          self.call 'Recipe.insert', result, (err, result)->
            console.warn ['Meteor::edit WARN', err] if err
            console.log ['Meteor::edit OK']



  return RecipeHelpersClass

RecipeHelpers.$inject = ['$q', '$timeout', 'utils', 'tileHelpers', 'AAAHelpers']

angular.module 'starter.recipe'
  .factory 'RecipeHelpers', RecipeHelpers
