express = require('express')
bodyParser = require('body-parser')

urlEncodedParser = bodyParser.urlencoded(extended: false)
class ChallengeServer
  constructor: (@bot) ->
    @app = express()

    @app.post '/challenge', urlEncodedParser, (req, res) =>
      challengerName = req.body.user_name
      challengerId = req.body.user_id
      opponentName = req.body.text.match(/@\w+/)[0].replace('@', '')
      opponentId = @bot.getUserByName(opponentName).id
      @bot.challenge(challengerId, opponentId)

      challengeCopy = "#{opponentName} (#{opponentId}) has been challenged by #{challengerName} (#{challengerId})"
      console.log challengeCopy
      res.send challengeCopy

   listen: (port) ->
     @app.listen(port)

module.exports = ChallengeServer
