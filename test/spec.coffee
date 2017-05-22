main = require '../src/main.coffee'
should = require 'should'

describe 'Git repositories', ->
  @timeout(15000)

  fetchOpts =
    callbacks:
      certificateCheck: () -> 1

  it 'can be cloned', ->
    main.getUpdatedRepo('https://github.com/nodegit/nodegit', 'master', './tmp', fetchOpts)
    .then (repo) ->
      repo.head()
    .should.have.eventually.property('name')


