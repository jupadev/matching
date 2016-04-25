async = require 'async'
Rater = require './rater'
Similars = require './similars'
Suggestions = require './suggestions'

module.exports = class Engine
	constructor: ->
		@users = new Rater @, 'users'
		@jobs = new Rater @, 'jobs'
		@similars = new Similars @
		@suggestions = new Suggestions @

