
_ = require 'lodash'
request = require 'request'
alfredo = require 'alfredo'
Session = require('flowdock').Session
q = require 'q'
fs = require 'fs'

config = require './config'

# Flowdock User
# id: 109506
# nick: 'Spinbot'
# email: 'dev@spingo.com'
# avatar: 'https://d2cxspbh1aoie1.cloudfront.net/avatars/local/14c0d1b1b92ae842b0e50e1e6ac657d93435fb96f6cd597fb2e334b7b6fb84fa/'
# name: 'Spinbot'
# website: ''

# Alfred Item
# title: "Message '#{params[0]}'"
# subtitle: "Send a message"
# valid: true
# autocomplete: "send"
# arg: "Cool test Bro!"

s = new Session config.apiToken

initCache = ->
  fs.mkdirSync config.cachePath unless fs.existsSync config.cachePath

download = (uri, filename) ->
  dfd = q.defer()
  request.head uri, (err, res, body) ->
    contentType = res.headers['content-type']
    ext = contentType.match(/\/(.+)$/)[1]
    request(uri)
      .pipe(fs.createWriteStream("#{filename}"))
      .on 'close', -> dfd.resolve()
  dfd

getUsers = ->
  dfd = q.defer()
  s.get "/users", {}, (err, flow, request) ->
    users = request.body
    promises = (downloadAvatar user for user in users)
    q.all(promises).then -> dfd.resolve users
  dfd.promise

userToItem = (user) ->
  new alfredo.Item
    title: user.name
    subtitle: "Go to #{user.name} in Flowdock"
    icon: "./cache/#{user.id}"
    autocomplete: user.name
    uid: user.id
    arg: "open #{user.id}"

downloadAvatar = (user) ->
  userAvatarPath = "#{config.cachePath}/#{user.id}"
  if fs.existsSync userAvatarPath
    q.resolve()
  else
    download user.avatar, userAvatarPath

filterUsers = (users, query) ->
  return users unless query
  matches = alfredo.fuzzy query, _.pluck users, 'name'
  _(users).indexBy('name').pick(matches).values().value()

COMMANDS =
  lookup: (query) ->
    getUsers().then (users) ->
      users = filterUsers users, query
      items = _.map users, userToItem
      alfredo.feedback items

  help: (command, query) ->
    console.log """
    Usage: node index.js command query
    Commands:
      lookup
      help
    """

# Main
[command, query, args...] = process.argv.slice(2)
initCache()

if COMMANDS[command]?
  COMMANDS[command](query)
else
  COMMANDS.help(command, query)
