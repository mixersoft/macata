'use strict'
# @ adds to global namespace
global = @

options = {
  'profile':
    fields:
      username: 1
      profile: 1
}

global['mcRecipes'] = mcRecipes = new Mongo.Collection('recipes', {
  # transform: null
})

mcRecipes.helpers = {
  isAdmin: (model, userId)->
    userId ?= Meteor.userId()
    return true if model.ownerId == userId
    return false

  fetchOwner: (model)->
    return Meteor.users.findOne(model.ownerId, options['profile'])

  findProfiles: (model)-> # use with publishComposite.children
    return Meteor.users.find(model.ownerId, options['profile'])
}

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
    return if model.type != 'Recipe'
    meId = this.userId
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
    return if model.type != 'Recipe'
    meId = this.userId
    model.favorites ?= []
    found = model.favorites.indexOf meId
    action =
      if found == -1
      then '$addToSet'
      else '$pull'
    modifier = {}
    modifier[action] = {"favorites": meId}  # e.g.  { $addToSet: {"likes": meId} }
    mcRecipes.update(model._id, modifier )
    #TODO: update Model.user().profile.favorites
    profileFavorite = {"profile.favorites": { _id: model._id, class: 'Recipe' }}
    modifier[action] = profileFavorite
    Meteor.user.update({_id: meId}, modifier )

    return

}


global['mcRecipes'].allow allow
Meteor.methods methods
