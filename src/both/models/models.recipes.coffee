'use strict'
# @ adds to global namespace
global = @

global['mcRecipes'] = mcRecipes = new Mongo.Collection('recipes')

methods = {

}

Meteor.methods methods
