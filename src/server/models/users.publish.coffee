'use strict'

# @ adds to global namespace
global = @

Meteor.publish 'userProfiles', ()->
  console.log ['publish userProfiles']
  return Meteor.users.find({}, {
    fields:
      username: 1
      profile: 1
    }
  )
