####
# This sample is published as part of the blog article at www.toptal.com/blog
# Visit www.toptal.com/blog and subscribe to our newsletter to read great posts
####

_ = require 'underscore'
async = require 'async'
Bourne = require 'bourne'
express = require 'express'
bodyParser = require 'body-parser'

skillsets = require './data/skillsets.json'

Engine = require './lib/engine'
engine = new Engine

app = express()
app.use bodyParser.json()
app.use bodyParser.urlencoded({ extended: true })
app.set 'views', "#{__dirname}/views"
app.set 'view engine', 'jade'

app.route('/users')
.post((req, res, next) ->
	console.log req.method, req.url
	console.log JSON.stringify(req.body)
	items = req.body.skillsets || []
	engine.users.add req.body.user, items, (err) =>
		if err?
			return next err

		res.redirect "/"
)

app.route('/jobs')
.post((req, res, next) ->
	console.log req.method, req.url
	console.log JSON.stringify(req.body)
	items = req.body.skillsets || []
	engine.jobs.add req.body.job, items, (err) =>
			if err?
				return next err

			res.redirect "/"
)

app.route('/generate')
.get(({query}, res, next) ->
	engine.suggestions.updateAll (err) =>
		if err?
			return next err
		res.redirect "/"
)

app.route('/')
.get(({query}, res, next) ->
	async.auto
		jobs: (done) =>
			engine.jobs.getAll done

		users: (done) =>
			engine.users.getAll done

		suggestions: (done) =>
			engine.suggestions.forUsers (err, suggestions) =>
				if err?
					return done err

				done null, suggestions

	, (err, {users, jobs, suggestions}) =>
		if err?
			return next err
		res.render 'index',
			user: query.user
			jobs: jobs,
			users: users,
			suggestions: suggestions
			skillsets: skillsets
)

app.listen (port = 5000), (err) ->
	if err?
		throw err

	console.log "Listening on #{port}"
