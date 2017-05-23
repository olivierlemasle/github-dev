main = require '../src/main.coffee'
should = require 'should'
Git = require 'nodegit'

describe 'Git repositories', ->
  @timeout(5000)

  url = 'https://github.com/olivierlemasle/plaintext-maven-plugin'
  fetchOpts =
    callbacks:
      certificateCheck: () -> 1

  it 'can be cloned', ->
    main.getUpdatedRepo(url, 'master', './tmp', fetchOpts)
    .should.eventually.be.instanceOf(Git.Repository)
