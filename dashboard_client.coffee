Client = require '../drsproboto/client'
polar = require 'polar'
util = require 'util'

pending_requests = {}

client_id = 'dashboard_client.sprobook'
dashboard_client = new Client
    name: client_id

dashboard_client.on 'message', (msg) ->
    console.log "-> #{ util.inspect msg }"

    if pending_request = pending_requests[msg.id]
        pending_request(msg)
        delete pending_requests[msg.id]

# Set up server

app = polar.setup_app
    port: 6655

# Define and generate REST routes

app.get '/', (req, res) ->
    res.render 'dashboard'

app.post '/script', (req, res) ->
    script = req.body.script
    sent_msg = dashboard_client.send
        type: 'script'
        script: script
        suppress: true
    pending_requests[sent_msg.id] = (message) =>
        console.log "[response for #{ sent_msg.id }] #{ util.inspect message }"
        res.setHeader 'content-type', 'application/json'
        res.end JSON.stringify message

app.get "/:collection.json", (req, res) ->
    console.log "sending list_#{ req.params.collection }"
    sent_msg = dashboard_client.send
        type: 'script'
        script: "list-#{ req.params.collection }"
        suppress: true
    console.log "sent msg: #{ sent_msg.id }"
    pending_requests[sent_msg.id] = (message) ->
        res.setHeader 'content-type', 'application/json'
        res.end JSON.stringify message.data

app.delete "/:collection/:_id.json", (req, res) ->
    sent_msg = dashboard_client.send
        type: 'script'
        script: "delete-#{ req.params.collection } #{ req.params._id }"
    pending_requests[sent_msg.id] = (message) ->
        res.setHeader 'content-type', 'application/json'
        res.end JSON.stringify message.data

app.post "/:collection.json", (req, res) ->
    new_item = req.body
    if req.params.collection=='behaviors' and new_item.query?
        new_item.query = JSON.parse new_item.query
    sent_msg = dashboard_client.send
        type: 'script'
        script: "create-#{ req.params.collection }"
        data: new_item
        suppress: true
    pending_requests[sent_msg.id] = (message) ->
        res.setHeader 'content-type', 'application/json'
        res.end JSON.stringify message.data

app.put "/:collection/:_id.json", (req, res) ->
    item_id = req.params._id
    updated_item = req.body
    delete updated_item['_id']
    if req.params.collection=='behaviors' and updated_item.query?
        updated_item.query = JSON.parse updated_item.query
    #console.log "hopefully will update #{ item_id } to #{ util.inspect updated_item }"
    sent_msg = dashboard_client.send
        type: 'script'
        script: "update-#{ req.params.collection } #{ item_id }"
        data: updated_item
        suppress: true
    pending_requests[sent_msg.id] = (message) ->
        res.setHeader 'content-type', 'application/json'
        res.end JSON.stringify updated_item

app.start()
