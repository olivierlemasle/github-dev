Git = require('nodegit')
pomParser = require('pom-parser')

logRepo = (repo) ->
  headPromise = repo.head().then (ref) -> ref.name()
  headCommitPromise = repo.getHeadCommit().then (commit) -> commit.sha()
  Promise.all [headPromise, headCommitPromise]
  .then (res) ->
    [head, commit] = res
    console.log "HEAD=#{head} - #{commit}"

checkoutNewBranch = (repo, branch) ->
  repo.getBranchCommit("refs/remotes/origin/#{branch}")
  .then (commit) ->
    repo.createBranch branch, commit, false

checkoutAndPullBranch = (repo, branch) ->
  repo.checkoutBranch(branch)
  .then () ->
    repo.mergeBranches(branch, "origin/#{branch}")

getUpdatedRepo = (url, branch, localPath, fetchOptions) ->
  cloneOptions =
    checkoutBranch: branch
    fetchOpts: fetchOptions
 
  console.log "Cloning #{url} to #{localPath}..."

  Git.Clone(url, localPath, cloneOptions)
  .catch (e) ->
 
    console.log "Cannot clone #{url} to #{localPath}: #{e}"
    console.log 'Trying to open existing git repository...'

    Git.Repository.open(localPath)
    .then (repo) ->
      repository = repo
      console.log 'Fetching from remotes...'

      repository.fetchAll(fetchOptions)
      .then () ->
        checkoutNewBranch repository, branch
      .catch () ->
        checkoutAndPullBranch repository, branch
      .then () ->
        repository
  .then (repo) ->
    logRepo(repo)
    repo

getMvnProjectVersion = (path) ->
  pomPath = path + '/pom.xml'
  console.log "Path: #{pomPath}"
  opts =
    filePath: pomPath
  new Promise (res, rej) ->
    pomParser.parse opts, (err, pomResponse) ->
      if err
        return rej(err)
      version = pomResponse.pomObject.project.version
      res(version)

module.exports =
  getUpdatedRepo: getUpdatedRepo
  getMvnProjectVersion: getMvnProjectVersion

