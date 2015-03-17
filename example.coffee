Slack = require('slack-client')
express = require('express')
bodyParser = require('body-parser')
_ = require('underscore')

token = process.env.TOKEN
channelName = process.env.CHANNEL
unless channelName
  console.log "missing CHANNEL on command line"
  process.exit()

process.title = "pingpong slack bot"
autoReconnect = true
autoMark = true

slack = new Slack(token, autoReconnect, autoMark)

users = {}
channels = {}
challenges = []
leaderboard = []

slack.on 'open', ->
  channel = slack.getChannelByName(channelName)
  channels.test = channel
  console.log "PINGPONG BOT IS CONNECTED"

getUserFromID = (id) ->
  user = users[id] || slack.getUserByID(id)
  users[id] = user
  user

_helpText =
  """
  `/challenge @user` to challenge `@user` ANYWHERE

  Pro-Tip: All commands can either be sent to `##{channelName}` or DM to `@pingpong` privately
  `leaderboard` to see the results of the last matches
  `challenge @user` to challenge `@user` in `##{channelName}`
  `challenges` to view all challenges
  `accept @user` to accept a challenge from someone
  `accept` to accept the latest challenge
  `@winner beat @loser 2-1` to register a victory

  """

_challenge = (userId, opponentId) ->
  user = getUserFromID(userId)
  opponent = getUserFromID(opponentId)
  response = "#{user.name} has challenged #{opponent.name}!!!"
  channels.test.send response
  challenges.push {challenger: user.id, opponent: opponent.id}

  slack.openDM opponent.id, (dm) ->
    dmChannel = slack.getChannelGroupOrDMByID(dm.channel.id)
    dmChannel.send "You have been challenged by #{user.name}"

_accept = (opponentId, challengerId) ->
  openChallenges = _.filter challenges, ({challenger, opponent}) ->
    opponentId == opponent
  if openChallenges.length == 1
    opponent = getUserFromID(opponentId)
    if challengerId
      challenger = getUserFromID(challengerId)
    else
      challenger = getUserFromID(openChallenges[0].challenger)
    channels.test.send "#{opponent.name} accepted challenge from #{challenger.name}"
  else if openChallenges.length > 1 && challengerId
    challenge = _.filter openChallenges, ({challenger, opponent}) ->
      opponentId == opponent && challengerId == challenger
    if challenge
      challenger = getUserFromID(challengerId)
      opponent = getUserFromID(opponentId)
      channels.test.send "#{opponent.name} accepted challenge from #{challenger.name}"
  else
    console.log "accept borked"

_leaderboard = ->
  if leaderboard.length == 0
    "No Matches Played"
  else
    text = "Latest Matches :trophy:\n"
    for score in leaderboard
      text += printScore(score)

    text

printScore = ({winner, loser, score}) ->
  "#{winner.name} beat #{loser.name} #{score || ''}\n"

_win = (winnerID, loserID, text) ->
  winner = getUserFromID(winnerID)
  loser = getUserFromID(loserID)
  matchScore = text.match(/\d+\-\d+/)?[0]
  score = {winner: winner, loser: loser, score: matchScore}
  leaderboard.push(score)
  printScore(score)

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
  {type, ts, text} = message

  if type is 'message' and text?
    mentionedUsers = text.match(/\<\@\w+\>/g)?.map (i) -> i.replace('<@', '').replace('>', '')

    if text.match(/accept/)
      if mentionedUsers?[0]
        _accept(message.user, mentionedUsers[0])
      else
        _accept(message.user)
    else if text.match(/challenges/)
      fromChan = slack.getChannelGroupOrDMByID(message.channel)
      fromChan.send(allChallenges())
    else if text.match(/leaderboard/)
      fromChan = slack.getChannelGroupOrDMByID(message.channel)
      fromChan.send(_leaderboard())
    else if mentionedUsers?.length == 1
        if text.match(/challenge/)
          _challenge(message.user, mentionedUsers[0])
        else
          console.log "no match with '#{text}'"
    else if mentionedUsers?.length == 2
      if text.match(/beat/)
        score = _win(mentionedUsers[0], mentionedUsers[1], text)
        channels.test.send(":trophy: #{score}")
    else if text == "help" || text == "halp"
      fromChan = slack.getChannelGroupOrDMByID(message.channel)
      fromChan.send(_helpText)
    else
      console.log "no mas '#{text}'"

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
