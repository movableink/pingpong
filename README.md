# pingpong
This is our pingpong Slack bot...named `@pingpong`.

Getting Started
--------------

### Setup the Bot
 
1. Make sure you're logged in to Slack and navigate to the [new services page](https://ink.slack.com/services/new).

2. Scroll down to find the "Bots" section and click "Add"
    ![screen shot 2015-03-26 at 3 29 15 pm](https://cloud.githubusercontent.com/assets/27777/6855263/0d66d21e-d3cd-11e4-8d95-1c0bc11b348e.png)

3. Name thy Bot
  ![screen shot 2015-03-26 at 3 31 00 pm](https://cloud.githubusercontent.com/assets/27777/6855272/2a0d92b8-d3cd-11e4-9d46-0141bcc739cd.png)

4. Save your API Token!!
  ![screen shot 2015-03-26 at 3 32 41 pm](https://cloud.githubusercontent.com/assets/27777/6855324/80cbf220-d3cd-11e4-9258-5d35de120ff8.png)

5. Give it a face
  ![bot-face](https://cloud.githubusercontent.com/assets/27777/6855409/39b05efc-d3ce-11e4-8b7f-51b6c76b896a.png)

6. Give it a purpose
  ![bot-purpose](https://cloud.githubusercontent.com/assets/27777/6855411/458830d8-d3ce-11e4-879f-70cfe35fc4be.png)

7. Save!

Additional API details are [here](https://api.slack.com/bot-users)

### Setup the Slash Command

1. Once again make sure you're logged in to Slack and navigate to the [new services page](https://ink.slack.com/services/new).

2. Scroll to the bottom to find the "Slash Commands" section and click on "Add"
  ![screen shot 2015-03-26 at 2 58 42 pm](https://cloud.githubusercontent.com/assets/27777/6854813/ea1880a8-d3c9-11e4-9468-50cb4a43a9d1.png)

3. Add the actual command. We like `/challenge`
  ![screen shot 2015-03-26 at 3 21 17 pm](https://cloud.githubusercontent.com/assets/27777/6855083/ccac4e6c-d3cb-11e4-9e13-b5a8e81a61fd.png)

4. Add the URL that you'll be running `@pingpong` challenge server on
  ![slash-url](https://cloud.githubusercontent.com/assets/27777/6855509/4ab34cc2-d3cf-11e4-8bdb-8eaa585eea26.png)

5. Add some helpful text!
  ![slash-help](https://cloud.githubusercontent.com/assets/27777/6855518/6bb1775a-d3cf-11e4-9947-9fd4fd1b947c.png)

6. Add a label if you wish and save!
  ![slash-label](https://cloud.githubusercontent.com/assets/27777/6855535/9a327d22-d3cf-11e4-86f2-7fdd126e2e05.png)

### Setup the App
  1. Clone the repo at https://github.com/movableink/pingpong
  2. `npm install`
  3. start it up with `TOKEN={your token} CHANNEL={some channel} coffee app.coffee`
