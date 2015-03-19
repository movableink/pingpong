process.title = "pingpong slack bot"

token = process.env.TOKEN
channel = process.env.CHANNEL
unless channel
  console.log "missing CHANNEL on command line"
  process.exit()

Bot = require('./bot')
bot = new Bot(channel, token)
bot.engage()

ChallengeServer = require('./challenge_server')
server = new ChallengeServer(bot)
server.listen(1337)
