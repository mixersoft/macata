'use strict'
# @ adds to global namespace
global = @

options = {
  'profile':
    fields:
      username: 1
      displayName: 1
      face: 1
}

###
# see models.0.coffee
# usage:
#   hRecipes.get().fetchHost($item)
###
global['hRecipes'] = class RecipeHelper extends global['hModel']
  constructor: ->
    [@arg] = super


global['mcRecipes'] = mcRecipes = new Mongo.Collection('recipes', {
  # transform: null
})


allow = {
  insert: (userId, recipe)->
    return recipe.ownerId? # userId && recipe.ownerId == userId
  update: (userId, recipe, fields, modifier)->
    return userId && recipe.ownerId == userId
  remove: (userId, recipe)->
    return userId && recipe.ownerId == userId
}


methods = {
  'Recipe.toggleLike': (model)->
    return if model.className != 'Recipe'
    meId = Meteor.userId()
    model.likes ?= []
    found = model.likes.indexOf meId
    action =
      if found == -1
      then '$addToSet'
      else '$pull'
    modifier = {}
    modifier[action] = {"likes": meId}  # e.g.  { $addToSet: {"likes": meId} }
    mcRecipes.update(model._id, modifier )
    return

  'Recipe.toggleFavorite': (model)->
    return if model.className != 'Recipe'
    meId = Meteor.userId()

    model.favorites ?= []
    found = model.favorites.indexOf meId
    action =
      if found == -1
      then '$addToSet'   # TODO: this is not scalable
      else '$pull'
    modifier = {}
    modifier[action] = {"favorites": meId}  # e.g.  { $addToSet: {"likes": meId} }
    mcRecipes.update(model._id, modifier )
    #TODO: update Model.user().favorites
    modifier[action] = {"favorites": { _id: model._id, className: 'Recipe' }}
    Meteor.users.update({_id: meId}, modifier )
    return

  # TODO: use Events.upsert model
  'Recipe.insert': (model)->
    if !model
      throw new Meteor.Error('no-data'
      , 'Expecting something to insert', null
      )
    meId = Meteor.userId()
    data = _.pick model, [
      'url','title','description','image', 'site_name', 'extras'
      'lonlat', 'latlon'
    ]
    data['className'] = 'Recipe'
    data['createdAt'] = new Date()
    data['ownerId'] = meId
    hRecipes.get().setAsGeoJsonPoint(data)
    mcRecipes.insert(data)

  'Recipe.update': (model)->
    meId = Meteor.userId()
    # if model.className != 'Recipe'
    #   found = mcRecipes.findOne(model._id)
    #   if found.className != 'Recipe'
    #     throw new Meteor.Error('invalid-class'
    #     , 'className does not match', null
    #     )
    if model.ownerId != meId
      throw new Meteor.Error('no-permission'
      , 'You do not have permission to update', null
      )
    data = _.pick model, [
      'url','title','description','image', 'site_name', 'extras'
      'lonlat', 'latlon'
    ]
    data['modifiedAt'] = new Date()
    hRecipes.get().setAsGeoJsonPoint(data)

    # legacy: deprecate
    data['className'] = 'Recipe'
    data['createdAt'] = new Date()

    modifier = {}
    modifier['$set'] = data
    # console.log modifier
    mcRecipes.update(model._id, modifier )
    return

}


global['mcRecipes'].allow allow
Meteor.methods methods
