'use strict'
# @ adds to global namespace
global = @

options = {
  'profile':
    fields:
      username: 1
      profile: 1
}

class RecipeModel
  constructor: (event)->
    _.extend(@, event)

  fetchOwner: =>
    return Meteor.users.findOne(@ownerId, options['profile'])

  fetchProfiles: => # use with publishComposite.children
    return Meteor.users.find(@ownerId, options['profile'])


global['mcRecipes'] = mcRecipes = new Mongo.Collection('recipes', {
  transform: (event)->
    return new RecipeModel(event)
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
}


global['mcRecipes'].allow allow
Meteor.methods methods
