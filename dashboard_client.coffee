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

list_ = (type) ->
    app.get "/#{ type }s.json", (req, res) ->
        console.log "sending list_#{ type }s"
        sent_msg = dashboard_client.send
            type: 'script'
            script: "list-#{ type }s"
            suppress: true
        console.log "sent msg: #{ sent_msg.id }"
        pending_requests[sent_msg.id] = (message) ->
            res.setHeader 'content-type', 'application/json'
            res.end JSON.stringify message.data

delete_ = (type) ->
    app.delete "/#{ type }s/:_id.json", (req, res) ->
        sent_msg = dashboard_client.send_message
            receiver: "delete-#{ type }"
            query:
                _id: req.params._id
        pending_requests[sent_msg.id] = (message) ->
            res.setHeader 'content-type', 'application/json'
            res.end JSON.stringify message.data

create_ = (type) ->
    app.post "/#{ type }s.json", (req, res) ->
        new_item = req.body
        if type=='behavior' and new_item.query?
            new_item.query = JSON.parse new_item.query
        sent_msg = dashboard_client.send_message
            receiver: "create-#{ type }"
            data: new_item
            suppress: true
        pending_requests[sent_msg.id] = (message) ->
            res.setHeader 'content-type', 'application/json'
            res.end JSON.stringify message.data

update_ = (type) ->
    app.put "/#{ type }s/:_id.json", (req, res) ->
        item_id = req.params._id
        updated_item = req.body
        delete updated_item['_id']
        if type=='behavior' and updated_item.query?
            updated_item.query = JSON.parse updated_item.query
        #console.log "hopefully will update #{ item_id } to #{ util.inspect updated_item }"
        sent_msg = dashboard_client.send_message
            script: "update-#{ type }"
            args:
                _id: item_id
            data: updated_item
            suppress: true
        pending_requests[sent_msg.id] = (message) ->
            res.setHeader 'content-type', 'application/json'
            res.end JSON.stringify updated_item

for type in ['action', 'behavior', 'message', 'email', 'tweet', 'github_event']
    list_ type
    delete_ type
    create_ type
    update_ type

app.start()
