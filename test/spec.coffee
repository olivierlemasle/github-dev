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


describe 'On a Maven project', ->
  @timeout(5000)

  url = 'https://github.com/olivierlemasle/plaintext-maven-plugin'
  path = './tmp'
  fetchOpts =
    callbacks:
      certificateCheck: () -> 1

  it 'version can be retrieved', ->
    main.getUpdatedRepo(url, 'master', path, fetchOpts)
    .then (repo) ->
      main.getMvnProjectVersion(path)
    .should.eventually.endWith '-SNAPSHOT'
