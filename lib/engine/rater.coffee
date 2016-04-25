_ = require 'underscore'
async = require 'async'
Bourne = require 'bourne'

module.exports = class Rater
	constructor: (@engine, @kind) ->
		@db = new Bourne "./bourne_db/db-#{@kind}.json"

	add: (name, items, done) ->
		items = if _.isString(items) then [items] else items
		items = _.map items, (item) =>
				return JSON.parse item

		@db.find name: name, (err, res) =>
			if err?
				return done err

			if res.length > 0
				return done()
			console.log 'items length: ' + items.length
			
			@db.insert name: name, items: items, (err, result) =>
				if err?
					return done err

				async.series [
					(done) =>
						@engine.similars.update name, @kind, result.id, done
					(done) =>
						@engine.suggestions.update name, @kind, result.id, done
				], done

	remove: (name, item, done) ->
		@db.delete name: name, item: item, (err) =>
			if err?
				return done err

			async.series [
				(done) =>
					@engine.similars.update name, done
				(done) =>
					@engine.suggestions.update name, done
			], done

	itemsByUser: (user, done) ->
		@db.find name: user, (err, results) =>
			if err?
				return done err

			done null, _.pluck results, 'items'

	usersByItem: (item, done) ->
		@db.find item: item, (err, ratings) =>
			if err?
				return done err

			done null, _.pluck ratings, 'user'

	getAll: (done) ->
		@db.find null, (err, results) =>
			if err?
				return done err

			done null, results
