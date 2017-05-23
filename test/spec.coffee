main = require '../src/main.coffee'
should = require 'should'
Git = require 'nodegit'
rmdir = require 'rmdir'

path = './tmp'

beforeEach 'Clean', (done) ->
  rmdir path, (err, dirs, files) ->
    if err
      return done(err)
    done()

describe 'Git repositories', ->
  @timeout(15000)

  url = 'https://github.com/olivierlemasle/java-certificate-authority'
  fetchOpts =
    callbacks:
      certificateCheck: () -> 1

  it 'can be cloned', ->
    main.getUpdatedRepo(url, 'master', path, fetchOpts)
    .should.eventually.be.instanceOf(Git.Repository)

  it 'can be pulled', ->
    main.getUpdatedRepo(url, 'master', path, fetchOpts)
    .then () ->
      main.getUpdatedRepo(url, 'master', path, fetchOpts)
    .should.eventually.be.instanceOf(Git.Repository)


describe 'On a Maven project', ->
  @timeout(15000)

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
