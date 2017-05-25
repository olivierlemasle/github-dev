GithubDev = require('../src/main.coffee').GithubDev
should = require 'should'
git = require 'nodegit'
del = require 'del'
fs = require 'fs'

path = './tmp'
pathFile = './tmp/file'

beforeEach 'Clean', ->
  del.sync([path])

describe 'Git repositories', ->
  @timeout(15000)

  url = 'https://github.com/olivierlemasle/repo-test'
  githubAuth = githubRepoOwner = githubRepo = null
  fetchOpts = pushOpts =
    callbacks:
      certificateCheck: -> 1

  it 'can be cloned on master branch', ->
    new GithubDev(url, 'master', fetchOpts, pushOpts, path, githubAuth, githubRepoOwner, githubRepo).fetch()
    .should.eventually.be.instanceOf(git.Repository)
    .then ->
      fs.readFileSync(pathFile, 'utf8').should.startWith 'new'

  it 'can be pulled on master branch', ->
    repository = null
    new GithubDev(url, 'master', fetchOpts, pushOpts, path, githubAuth, githubRepoOwner, githubRepo).fetch()
    .then (repo) ->
      repository = repo
      repo.getCommit('b61aad284193010c9419b9ebee69ce1004fd097f')
    .then (oldCommit) ->
      git.Reset.reset(repository, oldCommit, git.Reset.TYPE.HARD)
    .then ->
      fs.readFileSync(pathFile, 'utf8').should.startWith 'old'
    .then ->
      new GithubDev(url, 'master', fetchOpts, pushOpts, path, githubAuth, githubRepoOwner, githubRepo).fetch()
    .then ->
      fs.readFileSync(pathFile, 'utf8').should.startWith 'new'

  it 'can be cloned on another branch', ->
    new GithubDev(url, 'other', fetchOpts, pushOpts, path, githubAuth, githubRepoOwner, githubRepo).fetch()
    .then ->
      fs.readFileSync(pathFile, 'utf8').should.startWith 'other'

  it 'can checkout another branch', ->
    new GithubDev(url, 'master', fetchOpts, pushOpts, path, githubAuth, githubRepoOwner, githubRepo).fetch()
    .then ->
      fs.readFileSync(pathFile, 'utf8').should.startWith 'new'
    .then ->
      new GithubDev(url, 'other', fetchOpts, pushOpts, path, githubAuth, githubRepoOwner, githubRepo).fetch()
    .then ->
      fs.readFileSync(pathFile, 'utf8').should.startWith 'other'

  it 'can pull on another branch', ->
    repository = null
    new GithubDev(url, 'master', fetchOpts, pushOpts, path, githubAuth, githubRepoOwner, githubRepo).fetch()
    .then ->
      new GithubDev(url, 'other', fetchOpts, pushOpts, path, githubAuth, githubRepoOwner, githubRepo).fetch()
    .then (repo) ->
      repository = repo
      repo.getCommit('b61aad284193010c9419b9ebee69ce1004fd097f')
    .then (oldCommit) ->
      git.Reset.reset(repository, oldCommit, git.Reset.TYPE.HARD)
    .then ->
      fs.readFileSync(pathFile, 'utf8').should.startWith 'old'
    .then ->
      new GithubDev(url, 'other', fetchOpts, pushOpts, path, githubAuth, githubRepoOwner, githubRepo).fetch()
    .then ->
      fs.readFileSync(pathFile, 'utf8').should.startWith 'other'


describe 'On a Maven project', ->
  @timeout(15000)

  url = 'https://github.com/olivierlemasle/plaintext-maven-plugin'
  githubAuth = githubRepoOwner = githubRepo = null
  path = './tmp'
  fetchOpts = pushOpts =
    callbacks:
      certificateCheck: -> 1

  it 'version can be retrieved', ->
    dev = new GithubDev(url, 'master', fetchOpts, pushOpts, path, githubAuth, githubRepoOwner, githubRepo)
    dev.fetch()
    .then (repo) ->
      dev.getMvnProjectVersion()
    .should.eventually.endWith '-SNAPSHOT'

describe 'A change can be requested', ->
  @timeout(15000)

  url = 'https://github.com/olivierlemasle/repo-test'
  githubAuth = githubRepoOwner = githubRepo = null
  fetchOpts = pushOpts =
    callbacks:
      certificateCheck: -> 1

  it 'using a CLI command', ->
    dev = new GithubDev(url, 'master', fetchOpts, pushOpts, path, githubAuth, githubRepoOwner, githubRepo)
    dev.fetch()
    .then (repo) ->
      dev.requestChange repo, 'change', 'message', 'pr', 'prBody', false, ->
        require('mz/fs').writeFile(path + '/example.txt', 'Hello')
    .should.eventually.be.instanceOf(String)

