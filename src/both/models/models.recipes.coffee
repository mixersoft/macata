'use strict'
# @ adds to global namespace
global = @

global['mcRecipes'] = mcRecipes = new Mongo.Collection('recipes')

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
