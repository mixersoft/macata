'use strict'

# @ adds to global namespace
global = @

###
# NOTE: publish functions can only use this.userid
#   Meteor.methods can use Meteor.user() from both client & server
###
_getUser = (userId)->
  return Meteor.users.findOne(userId)


Meteor.publishComposite 'myEventFeeds', (filterBy, options)->
  # console.log ['publish feeds', options]
  selector = {
    $and: []
  }
  if not _.isEmpty filterBy
    eventId = filterBy['eventId'] || -1
    delete filterBy['eventId']
    selector['$and'].push {'head.eventId': eventId}
    selector['$and'].push filterBy if not _.isEmpty filterBy
  else
    selector['$and'].push false

  console.log ['publish feeds', JSON.stringify( selector ), 'userId=' + this.userId ]

  result = {
    find: ()->
      found = global['mcFeeds'].find(selector, options)
      global['Counts'].publish(this, 'countFeeds', found, {noReady: true})
      console.log ["countFeeds, server count=", found.count()]

      return global['mcFeeds'].find(selector, options)
    children: [
      {
        find: (feed)-> return FeedModel::findAttachment(feed)
      }
    ]
  }

  return result
