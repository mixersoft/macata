'use strict'

# @ adds to global namespace
global = @

###
# NOTE: publish functions can only use this.userid
#   Meteor.methods can use Meteor.user() from both client & server
###
_getUser = (userId)->
  return Meteor.users.findOne(userId)


Meteor.publishComposite 'myVisibleEvents', (filterBy, options)->
  # console.log ['publish events', options]
  # TODO: use check() to validate options
  selector = {
    $or: [
      {
        $and: [
          {'ownerId': this.userId}
          {'ownerId': {$exists: true} }
        ]
      }
    , {
        participantIds: this.userId
      }
    , {
        'isPublic': {$eq: true}
      }
    ]
  }
  if not _.isEmpty filterBy
    selector = {
      $and: [
        selector
        filterBy
      ]
    }
  # console.log ['publish events', JSON.stringify( selector ), 'userId=' + this.userId ]
  result = {
    find: ()->
      found = global['mcEvents'].find(selector, options)
      global['Counts'].publish(this, 'countEvents', found, {noReady: true})
      console.log ["countEvents, server count=", found.count()]

      return global['mcEvents'].find(selector, options)
    children: [
      {
        find: (event)->
          return hEvents.get().findParticipants(event)
      }
      {
        find: (event)->
          return hEvents.get().findMenuItems(event)
      }
    ]
  }


  return result
