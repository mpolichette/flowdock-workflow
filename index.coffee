
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


# Main
args = process.argv
[program, filePath, command] = args

s = new Session config.apiToken

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
    dfd.resolve request.body
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


getUsers().then (users) ->
  fs.mkdirSync config.cachePath unless fs.existsSync config.cachePath
  promises = (downloadAvatar user for user in users)
  q.all(promises).then ->
    items = _.map users, userToItem
    alfredo.feedback items
