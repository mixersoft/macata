'use strict'

# @ adds to global namespace
global = @

Meteor.publish 'userProfiles', ()->
  console.log ['publish userProfiles']
  return Meteor.users.find({}, {
    fields:
      username: 1
      firstname: 1
      lastname: 1
      displayName: 1
      face: 1
      gender: 1
      emails: 1
      profile: 1
      'services.facebook.id': 1
      'services.facebook.username': 1
      'services.facebook.gender': 1
    }
  )

Meteor.publish 'myProfile', ()->
  console.log ['publish myself']
  return Meteor.users.find({}, {
    fields:
      username: 1
      firstname: 1
      lastname: 1
      displayName: 1
      face: 1
      gender: 1
      emails: 1
      profile: 1
      favorites: 1
      location: 1
      pastLocations: 1
      'services.facebook': 1
    }
  )


Accounts.onCreateUser (options, user)->
  # console.log 'Accounts.onCreateUser'
  if facebook = user.services.facebook
    # for oauth errors, check: Accounts.oauth.tryLoginAfterPopupClosed()
    user.firstname = facebook.first_name
    user.lastname = facebook.last_name
    fbPic = ['http://graph.facebook.com',facebook.id,'picture'].join('/') + '?type=large'
    user.displayName = facebook.name
    user.face = fbPic
    user.gender = facebook.gender
    if _.isEmpty user.emails
      # doesn't work w/onCreateUser
      # Accounts.addEmail(user._id, facebook.email, true)
      user.emails = [{address: facebook.email, verified: true}]
    else
      found = _.findIndex user.emails, (o)->
        return true if o.address.toUpperCase() == facebook.email.toUpperCase()
      if found == -1
        user.emails.push {address: facebook.email, verified: true}
      else
        user.emails.splice(found, 1)

  if user.services.twitter
    angular.noop()

  # console.log user
  return user
