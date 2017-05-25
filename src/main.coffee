git       = require 'nodegit'
pomParser = require 'pom-parser'
githubApi = require 'github'

class GithubDev
  constructor: (@gitUrl, @baseBranch, @fetchOptions, @pushOptions, @localPath,
                @githubAuth, @githubRepoOwner, @githubRepo,
                @authorName = 'GithubDev', @authorEmail = 'example@example.net',
                @remote = 'origin') ->

  fetch: ->
    cloneOptions =
      checkoutBranch: @baseBranch
      fetchOpts: @fetchOptions

    console.log "Cloning #{@gitUrl} to #{@localPath}..."

    git.Clone(@gitUrl, @localPath, cloneOptions)
    .catch (e) =>

      console.log "Cannot clone #{@gitUrl} to #{@localPath}: #{e}"
      console.log 'Trying to open existing git repository...'

      git.Repository.open(@localPath)
      .then (repo) =>
        repository = repo
        console.log 'Fetching from remotes...'

        repository.fetchAll(@fetchOptions)
        .then =>
          @checkoutNewBranchFromRemote repo
        .catch =>
          console.log 'Local branch already existing'
          @checkoutAndPullBranchFromRemote repo
        .then ->
          repository
    .then (repo) =>
      @logRepo(repo)
      repo

  getMvnProjectVersion: ->
    pomPath = @localPath + '/pom.xml'
    console.log "Path: #{pomPath}"
    opts =
      filePath: pomPath
    new Promise (res, rej) ->
      pomParser.parse opts, (err, pomResponse) ->
        if err
          return rej(err)
        version = pomResponse.pomObject.project.version
        res(version)

  requestChange: (repo, changeBranch, message, prTitle, prBody, pushChange,
    change) ->
    index = oid = null
    @createAndCheckoutNewBranch(repo, changeBranch)
    .then ->
      change()
    .then ->
      repo.refreshIndex()
    .then (idx) ->
      index = idx
      index.addAll()
    .then ->
      index.write()
    .then ->
      index.writeTree()
    .then (oidResult) ->
      oid = oidResult
      git.Reference.nameToId(repo, 'HEAD')
    .then (head) ->
      repo.getCommit(head)
    .then (parent) =>
      author = git.Signature.now(@authorName, @authorEmail)
      repo.createCommit('HEAD', author, author, message, oid, [parent])
    .then =>
      if (!pushChange)
        return Promise.resolve(oid.tostrS())
      repo.getRemote(@remote)
      .then (remote) =>
        refSpec = "refs/heads/#{changeBranch}:refs/heads/#{changeBranch}"
        remote.push [refSpec], @pushOptions
      .then =>
        github = new githubApi {Promise: require('bluebird')}
        github.authenticate(@githubAuth)
        github.pullRequests.create {
          owner: @githubRepoOwner,
          repo: @githubRepo,
          title: prTitle,
          head: changeBranch,
          base: @baseBranch,
          body: prBody
        }

  checkoutNewBranchFromRemote: (repo) ->
    console.log "Creating local branch from #{@remote}/#{@baseBranch}"
    repo.getBranchCommit("refs/remotes/#{@remote}/#{@baseBranch}")
    .then (commit) =>
      repo.createBranch @baseBranch, commit, false
    .then (ref) =>
      console.log "Checkout branch #{@baseBranch}"
      repo.checkoutBranch(ref)

  checkoutAndPullBranchFromRemote: (repo) ->
    console.log "Checkout branch #{@baseBranch}"
    repo.checkoutBranch(@baseBranch)
    .then =>
      console.log "Pulling from #{@remote}/#{@baseBranch}"
      repo.mergeBranches(@baseBranch, "#{@remote}/#{@baseBranch}")

  logRepo: (repo) ->
    headPromise = repo.head().then (ref) -> ref.name()
    headCommitPromise = repo.getHeadCommit().then (commit) -> commit.sha()
    Promise.all [headPromise, headCommitPromise]
    .then (res) ->
      [head, commit] = res
      console.log "HEAD=#{head} - #{commit}"

  createAndCheckoutNewBranch: (repo, newBranch) ->
    repo.getBranchCommit(@baseBranch)
    .then (commit) ->
      repo.createBranch newBranch, commit, false
    .then (ref) ->
      console.log "Checkout branch #{newBranch}"
      repo.checkoutBranch(ref)
    .then ->
      repo

module.exports =
  GithubDev: GithubDev

