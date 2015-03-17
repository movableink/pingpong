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

_challenge = (userId, opponentId) ->
  user = getUserFromID(userId)
  opponent = getUserFromID(opponentId)
  response = "#{user.name} has challenged #{opponent.name}!!!"
  channels.test.send response
  challenges.push {challenger: user.id, opponent: opponent.id}

  slack.openDM opponent.id, (dm) ->
    dmChannel = slack.getChannelGroupOrDMByID(dm.channel.id)
    dmChannel.send "You have been challenged by #{opponent.name}"

allChallenges = ->
  if challenges.length == 0
    "No Challenges"
  else
    text = "All Challenges\n"
    for {challenger, opponent} in challenges
      challengerUser = getUserFromID(challenger)
      opponentUser = getUserFromID(opponent)
      text += "#{challengerUser.name} vs #{opponentUser.name}\n"

    text

slack.on 'message', (message) ->
  console.log message
  {type, ts, text} = message

  if type is 'message' and text?
    mentionedUsers = text.match(/<@\w+>/)
    # if text.indexOf('challenge') > -1 && mentionedUsers.length == 1
    if mentionedUsers?.length == 1
        if text.match(/challenge/)
          _challenge(message.user, mentionedUsers[0].slice(2, -1))
        else if text.match(/accept/)
          challenge = _.filter challenges, ({challenger, opponent}) ->
            message.user == opponent
          if challenge
            channels.test.send "accepted"
        else
          console.log "no match with '#{text}'"
    else if text.match(/challenges/)
      channels.test.send(allChallenges())
    else
      console.log "no mention"

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
  _challenge(challengerId, opponentId)

  console.log "#{opponentName} (#{opponentId}) has been challenged by #{challengerName} (#{challengerId})"

server = app.listen(1337)
