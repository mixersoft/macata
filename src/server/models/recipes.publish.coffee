'use strict'

# @ adds to global namespace
global = @

Meteor.publishComposite 'myVisibleRecipes', (options)->
  console.log ['publish recipes']
  # TODO: use check() to validate options
  # TODO: add filter/sort/pagination
  result = {
    find: ()->
      return global['mcRecipes'].find({
        $or: [
          {
            $and: [
              {'ownerId': this.userId}
              {'ownerId': {$exists: true} }
            ]
          }
        , {
            $or: [
              {'isPrivate': {$exists: false} }
              {'isPrivate': false }
            ]
          }
        ]
      }, options)
    children: [
      {
        find: (recipe)-> return recipe.fetchProfiles()
      }
    ]
  }
  return result
