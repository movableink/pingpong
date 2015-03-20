Slack = require('slack-client')
_ = require('underscore')

formatScore = ({winner, loser, score}) ->
  "#{winner.name} beat #{loser.name} #{score || ''}\n"

class Bot

  constructor: (@channelName, @token) ->
    @users = {}
    @challenges = []
    @leaderboard = []
    @helpText =
      """
      `/challenge @user` to challenge `@user` ANYWHERE

      Pro-Tip: All commands can either be sent to `##{@channelName}` or DM to `@pingpong` privately
      `leaderboard` to see the results of the last matches
      `challenge @user` to challenge `@user` in `##{@channelName}`
      `challenges` to view all challenges
      `accept @user` to accept a challenge from someone
      `accept` to accept the latest challenge
      `@winner beat @loser 2-1` to register a victory

      """

  engage: ->
    @slack = new Slack(@token, true, true)
    @slack.on 'open', =>
      @channel = @slack.getChannelByName(@channelName)
      console.log "PINGPONG BOT IS CONNECTED"

    @slack.on 'message', (message) =>
      {type, ts, text} = message

      if type is 'message' and text?
        mentionedUsers = text.match(/\<\@\w+\>/g)?.map (i) -> i.replace('<@', '').replace('>', '')

        if text.match(/accept/)
          if mentionedUsers?[0]
            @_accept(message.user, mentionedUsers[0])
          else
            @_accept(message.user)
        else if text.match(/challenges/)
          fromChan = @slack.getChannelGroupOrDMByID(message.channel)
          fromChan.send(@_allChallenges())
        else if text.match(/leaderboard/)
          fromChan = @slack.getChannelGroupOrDMByID(message.channel)
          fromChan.send(@_leaderboard())
        else if mentionedUsers?.length == 1
            if text.match(/challenge/)
              @challenge(message.user, mentionedUsers[0])
            else
              console.log "no match with '#{text}'"
        else if mentionedUsers?.length == 2
          if text.match(/beat/)
            score = @_win(mentionedUsers[0], mentionedUsers[1], text)
            @channel.send(":trophy: #{score}")
        else if text == "help" || text == "halp"
          fromChan = @slack.getChannelGroupOrDMByID(message.channel)
          fromChan.send(@helpText)
        else
          console.log "no mas '#{text}'"

    @slack.on 'error', (error) ->
      console.error "Error: #{JSON.stringify(error)}"

    @slack.login()

  challenge: (userId, opponentId) ->
    user = @_getUserByID(userId)
    opponent = @_getUserByID(opponentId)
    response = "#{user.name} has challenged #{opponent.name}!!!"
    @channel.send response
    @challenges.push {challenger: user.id, opponent: opponent.id}

    @slack.openDM opponent.id, (dm) =>
      dmChannel = @slack.getChannelGroupOrDMByID(dm.channel.id)
      dmChannel.send "You have been challenged by #{user.name}"

  _allChallenges: ->
    if @challenges.length == 0
      "No Challenges"
    else
      text = "All Challenges\n"
      for {challenger, opponent} in @challenges
        challengerUser = @_getUserByID(challenger)
        opponentUser = @_getUserByID(opponent)
        text += "#{challengerUser.name} vs #{opponentUser.name}\n"

      text

  _win: (winnerID, loserID, text) ->
    winner = @_getUserByID(winnerID)
    loser = @_getUserByID(loserID)
    matchScore = text.match(/\d+\-\d+/)?[0]
    score = {winner: winner, loser: loser, score: matchScore}
    @leaderboard.push(score)
    formatScore(score)

  _leaderboard: ->
    if @leaderboard.length == 0
      "No Matches Played"
    else
      text = "Latest Matches :trophy:\n"
      for score in @leaderboard
        text += formatScore(score)

      text

  _accept: (opponentId, challengerId) ->
    openChallenges = _.filter @challenges, ({challenger, opponent}) ->
      opponentId == opponent
    if openChallenges.length == 1
      opponent = @_getUserByID(opponentId)
      if challengerId
        challenger = @_getUserByID(challengerId)
      else
        challenger = @_getUserByID(openChallenges[0].challenger)
      @channel.send "#{opponent.name} accepted challenge from #{challenger.name}"
    else if openChallenges.length > 1 && challengerId
      challenge = _.filter openChallenges, ({challenger, opponent}) ->
        opponentId == opponent && challengerId == challenger
      if challenge
        challenger = @_getUserByID(challengerId)
        opponent = @_getUserByID(opponentId)
        @channel.send "#{opponent.name} accepted challenge from #{challenger.name}"
    else
      console.log "accept borked"

  _getUserByID: (id) ->
    user = @users[id] || @slack.getUserByID(id)
    @users[id] = user
    user

  getUserByName: (name) ->
    @slack.getUserByName(name)

module.exports = Bot
