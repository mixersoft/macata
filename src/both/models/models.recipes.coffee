'use strict'
# @ adds to global namespace
global = @

options = {
  'profile':
    fields:
      username: 1
      profile: 1
}

###
#  NOTE: when calling from publish, set Meteor.userId() Meteor.user() explicitly
###
global['RecipeModel'] = class RecipeModel
  constructor: (@context)->
  set: (@context)->
  release: ()->
    delete @context

RecipeModel::isAdmin = (model, userId)->
  if @context
    model = @context
    [userid] = arguments      # required when called from publish
  return false if !model
  userId ?= Meteor.userId()   # available in Meteor.methods
  return false if !userId
  return true if model.ownerId == userId
  return false

RecipeModel::isFavorite = (model, me)->
  if @context
    model = @context
    [me] = arguments
  return false if !model
  me ?= Meteor.user()
  return false if !me
  return true if _.find me.profile.favorites, {_id: model._id}
  return false



RecipeModel::fetchOwner = (model={})->
  if @context
    model = @context
  return Meteor.users.findOne(model.ownerId, options['profile'])

RecipeModel::findProfiles = (model={})-> # use with publishComposite.children
  if @context
    model = @context
  return Meteor.users.find(model.ownerId, options['profile'])



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
    #TODO: update Model.user().profile.favorites
    profileFavorite = {"profile.favorites": { _id: model._id, className: 'Recipe' }}
    modifier[action] = profileFavorite
    Meteor.users.update({_id: meId}, modifier )
    return

}


global['mcRecipes'].allow allow
Meteor.methods methods
