'use strict'

# @ adds to global namespace
global = @

Meteor.publish 'all-recipes', ()->
  console.log ['publish recipes']
  return global['mcRecipes'].find({

    })
