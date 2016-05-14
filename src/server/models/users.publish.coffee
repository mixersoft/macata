'use strict'

# @ adds to global namespace
global = @

Meteor.publish 'userProfiles', (options)->
  # selector = _.pick options, ['_id', 'username']
  # return this.ready() if _.isEmpty selector
  selector = {}
  return Meteor.users.find(selector, {
    fields:
      # emails: 0
      username: 1
      firstname: 1
      lastname: 1
      displayName: 1
      face: 1
      gender: 1
      profile: 1
      'services.facebook.id': 1
      'services.facebook.username': 1
      'services.facebook.gender': 1
    }
  )

# Meteor.publish "userData", ()->
Meteor.publish 'myProfile', ()->
  return this.ready() if !this.userId
  return Meteor.users.find {_id: this.userId}, {
    fields:
      username: 1
      emails: 1
      profile: 1
      firstname: 1
      lastname: 1
      displayName: 1
      face: 1
      gender: 1
      favorites: 1
      location: 1
      pastLocations: 1
      'services.facebook': 1
  }


Accounts.onCreateUser (options, user)->
  # default behavior
  user.profile = options.profile if options.profile

  console.info ['Accounts.onCreateUser', user, options]

  # from accounts-password
  isAccountsPassword = options.username && (options.password || options.email)
  if isAccountsPassword
    # user = _.extend user, {}
    return user

  # from accounts-facebook
  if facebook = user.services.facebook
    # for oauth errors, check: Accounts.oauth.tryLoginAfterPopupClosed()
    user.username = _.startCase([facebook.name]).replace(/ /g,'')
    user.firstname = facebook.first_name
    user.lastname = facebook.last_name
    user.displayName = facebook.name
    fbPic = ['https://graph.facebook.com',facebook.id,'picture'].join('/') + '?type=large'
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
      return user

  if user.services.twitter
    return user

  # console.log user
  return user



# validateNewUser called AFTER onCreateUser()
Accounts.validateNewUser (user)->
  console.info(['Accounts.validateNewUser', user])
  baseSchema = {
    _id:
      type: String
      regEx: SimpleSchema.RegEx.Id
    firstname: {type: String, optional: true}
    lastname: {type: String, optional: true}
    face:
      type: String
      regEx: SimpleSchema.RegEx.Url
      optional: true
    displayName: {type: String, optional: true}
    gender: {type: String, optional: true}
    emails:
      type: [Object]
      optional: true
    'emails.$':
      type: Object
    "emails.$.address":
      type: String
      regEx: SimpleSchema.RegEx.Email
    "emails.$.verified":
      type: Boolean
    createdAt:
      type: Date
    services:
      type: Object
      blackbox: true
  }

  if facebook = user.services.facebook
    schema = new SimpleSchema(baseSchema)
  else if user.services.password
    pwdSchema = _.extend baseSchema, {
      username:
        type: String
        regEx: /^[a-z0-9A-Z_]{3,15}$/
    }
    schema = new SimpleSchema(pwdSchema)

  schema.clean(user)
  schema.validate(user)

  return true
