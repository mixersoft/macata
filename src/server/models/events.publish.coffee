'use strict'

# @ adds to global namespace
global = @

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
        'setting.isExclusive':
          $ne: true
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

  console.log ['publish events', JSON.stringify( selector ), 'userId=' + this.userId ]

  result = {
    find: ()->
      found = global['mcEvents'].find(selector, options)
      global['Counts'].publish(this, 'countEvents', found, {noReady: true})
      console.log ["countEvents, server count=", found.count()]

      return global['mcEvents'].find(selector, options)
    children: [
      {
        find: (event)-> return event.fetchParticipants()
      }
    ]
  }


  return result
