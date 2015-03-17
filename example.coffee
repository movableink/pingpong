# This is a simple example of how to use the slack-client module in CoffeeScript. It creates a
# bot that responds to all messages in all channels it is in with a reversed
# string of the text received.
#
# To run, copy your token below, then, from the project root directory:
#
# To run the script directly
#    npm install
#    node_modules/coffee-script/bin/coffee examples/simple_reverse.coffee
#
# If you want to look at / run / modify the compiled javascript
#    npm install
#    node_modules/coffee-script/bin/coffee -c examples/simple_reverse.coffee
#    cd examples
#    node simple_reverse.js
#

Slack = require('slack-client')
express = require('express')
bodyParser = require('body-parser')
_ = require('underscore')

token = process.env.SLACK_TOKEN # Add a bot at https://my.slack.com/services/new/bot and copy the token here.
autoReconnect = true
autoMark = true

slack = new Slack(token, autoReconnect, autoMark)

users = {}
channels = {}
challenges = []

slack.on 'open', ->
  channel = slack.getChannelByName('test')
  channels.test = channel
  # channel.sendMessage "hello world"
  console.log "PINGPONG BOT IS CONNECTED"

  #   groups = []
#   unreads = slack.getUnreadCount()

#   # Get all the channels that bot is a member of
#   channels = ("##{channel.name}" for id, channel of slack.channels when channel.is_member)

#   # Get all groups that are open and not archived
#   groups = (group.name for id, group of slack.groups when group.is_open and not group.is_archived)

  # console.log 'As well as: ' + groups.join(', ')

#   messages = if unreads is 1 then 'message' else 'messages'

#   console.log "You have #{unreads} unread #{messages}"

getUserFromID = (id) ->
  user = users[id] || slack.getUserByID(id)
  users[id] = user
  user

_challenge = (message, mentionedUsers) ->
  user = getUserFromID(message.user)
  opponent = getUserFromID(mentionedUsers[0].slice(2, -1))
  response = "#{user.name} has challenged #{opponent.name}!!!"
  channels.test.send response
  challenges.push {challenger: user.id, opponent: opponent.id}

  slack.openDM opponent.id, (dm) ->
    dmChannel = slack.getChannelGroupOrDMByID(dm.channel.id)
    dmChannel.send "You have been challenged by #{opponent.name}"

slack.on 'message', (message) ->
  console.log message
  {type, ts, text} = message

  if type is 'message' and text?
    mentionedUsers = text.match(/<@\w+>/)
    # if text.indexOf('challenge') > -1 && mentionedUsers.length == 1
    if mentionedUsers?.length == 1
        if text.match(/challenge/)
          _challenge(message, mentionedUsers)
        else if text.match(/accept/)
          challenge = _.filter challenges, ({challenger, opponent}) ->
            message.user == opponent
          if challenge
            channels.test.send "accepted"
        else
          console.log "no match with '#{text}'"
    else
      console.log "no mention"

#   channel = slack.getChannelGroupOrDMByID(message.channel)
#   user = slack.getUserByID(message.user)
#   response = ''

#   channelName = if channel?.is_channel then '#' else ''
#   channelName = channelName + if channel then channel.name else 'UNKNOWN_CHANNEL'

#   userName = if user?.name? then "@#{user.name}" else "UNKNOWN_USER"

#   console.log """
#     Received: #{type} #{channelName} #{userName} #{ts} "#{text}"
#   """

#   # Respond to messages with the reverse of the text received.
#   if type is 'message' and text? and channel?
#     response = text.split('').reverse().join('')
#     channel.send response
#     console.log """
#       @#{slack.self.name} responded with "#{response}"
#     """
#   else
#     #this one should probably be impossible, since we're in slack.on 'message'
#     typeError = if type isnt 'message' then "unexpected type #{type}." else null
#     #Can happen on delete/edit/a few other events
#     textError = if not text? then 'text was undefined.' else null
#     #In theory some events could happen with no channel
#     channelError = if not channel? then 'channel was undefined.' else null

#     #Space delimited string of my errors
#     errors = [typeError, textError, channelError].filter((element) -> element isnt null).join ' '

#     console.log """
#       @#{slack.self.name} could not respond. #{errors}
#     """


slack.on 'error', (error) ->
  console.error "Error: #{JSON.stringify(error)}"

slack.login()

app = express()
urlEncodedParser = bodyParser.urlencoded(extended: false)

app.post '/challenge', urlEncodedParser, (req, res) ->
  challengerName = req.body.user_name
  challengerId = req.body.user_id
  opponentName = req.body.text.match(/@\w+/)[0].replace('@', '')
  opponentId = slack.getUserByName(opponentName).id

  console.log "#{opponentName} (#{opponentId}) has been challenged by #{challengerName} (#{challengerId})"

server = app.listen(1337)
