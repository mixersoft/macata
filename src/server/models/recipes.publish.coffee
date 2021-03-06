'use strict'

# @ adds to global namespace
global = @
mcRecipes = global['mcRecipes']
hRecipes = global['hRecipes']

###
# NOTE: publish functions can only use this.userid
#   Meteor.methods can use Meteor.user() from both client & server
###
_getUser = (userId)->
  return Meteor.users.findOne(userId)

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
  # console.log ['publish recipes, options=', JSON.stringify( options )]
  result = {
    find: ()->
      return mcRecipes.find(selector, options)
    children: [
      {
        find: (recipe)->
          return hRecipes.get().findOwner(recipe)
      }
    ]
  }
  return result
