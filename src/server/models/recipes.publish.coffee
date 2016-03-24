'use strict'

# @ adds to global namespace
global = @
mcRecipes = global['mcRecipes']

Meteor.publishComposite 'myVisibleRecipes', (filterBy={}, options={})->

  # TODO: use check() to validate options
  # TODO: add filter/sort/pagination
  selector = {
    $or: [
      {
        $and: [
          {'ownerId': this.userId}
          {'ownerId': {$exists: true} }
        ]
      }
      ,{'isPrivate': {$ne: true} }
    ]
  }
  if not _.isEmpty filterBy
    selector = {
      $and: [
        selector
        filterBy
      ]
    }

  # selector = {}
  console.log ['publish recipes, selector=', JSON.stringify( selector )]
  result = {
    find: ()->
      return mcRecipes.find(selector, options)
    children: [
      {
        find: (recipe)->
          return RecipeModel::findProfiles(recipe)
      }
    ]
  }
  return result
