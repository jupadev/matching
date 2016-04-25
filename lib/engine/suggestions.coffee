_ = require 'underscore'
async = require 'async'
Bourne = require 'bourne'

module.exports = class Suggestions
	constructor: (@engine) ->
		@db = new Bourne './bourne_db/db-suggestions.json'

	forUsers: (done) ->
		@db.find type: 'users', (err, results) ->
			if err?
				return done err

			done null, results

	update: (user, type, userId, done) ->
		@engine.similars.byUser user, (err, others) =>
			if err?
				return done err

			async.auto 
				likes: (done) =>
					@engine.likes.itemsByUser user, done

				dislikes: (done) =>
					@engine.dislikes.itemsByUser user, done

				items: (done) =>
					async.map others, (other, done) =>
						async.map [
							@engine.likes
							@engine.dislikes

						], (rater, done) =>
							rater.itemsByUser other.user, done

						, done

					, done

			, (err, {likes, dislikes, items}) =>
				if err?
					return done err

				items = _.difference _.unique(_.flatten items), likes, dislikes
				@db.delete user: user, (err) =>
					if err?
						return done err

					async.map items, (item, done) =>
						async.auto
							likers: (done) =>
								@engine.likes.usersByItem item, done

							dislikers: (done) =>
								@engine.dislikes.usersByItem item, done

						, (err, {likers, dislikers}) =>
							if err?
								return done err

							numerator = 0
							for other in _.without _.flatten([likers, dislikers]), user
								other = _.findWhere(others, user: other)
								if other?
									numerator += other.similarity

							done null,
								item: item
								weight: numerator / _.union(likers, dislikers).length

					, (err, suggestions) =>
						if err?
							return done err

						@db.insert
							user: user
							type: type,
							userId: userId
							suggestions: suggestions
						, done

	updateAll: (done) ->
		async.auto 
			users: (done) =>
				@engine.users.getAll done

			jobs: (done) =>
				@engine.jobs.getAll done
		, (err, {users, jobs}) =>
			if err?
				return done err
			
			similarity = (user, job) =>
				userSkills = _.pluck user.items, '_id'
				jobSkills = _.pluck job.items, '_id'
				shared = _.intersection userSkills, jobSkills
				notShared = _.difference jobSkills, userSkills
				notShared = _.union notShared, _.difference userSkills, jobSkills
				# console.log 'userSkills: ', JSON.stringify userSkills
				# console.log 'jobSkills: ', JSON.stringify jobSkills
				# console.log '    shared: ', JSON.stringify shared
				# console.log '    not shared: ', JSON.stringify notShared
				result = shared.length / (shared.length + notShared.length)
				console.log '    shared.length / (shared.length + notShared.length): ', result
				return {
					job: {
						name: job.name
						items: job.items
						id: job.id
					} 
					similarity: result
				}

			_.each users, (user) =>
				console.log '#################################'
				suggestions = _.map jobs, (job) =>
					return similarity user, job
				console.log 'Suggestion User: ', user.name, ' -> ', suggestions
				@db.update {userId: user.id }, {$set: { suggestions: suggestions } }, (err, result) =>
					if err?
						return done err
					console.log 'Update OK ', user.name, ' -> ', result
			done null
					