git = require('nodegit')
pomParser = require('pom-parser')

class GithubDev
  constructor: (@gitUrl, @baseBranch, @fetchOptions, @localPath,
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

module.exports =
  GithubDev: GithubDev
