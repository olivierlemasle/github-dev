Git = require('nodegit')
pomParser = require('pom-parser')

logRepo = (repo) ->
  headPromise = repo.head().then (ref) -> ref.name()
  headCommitPromise = repo.getHeadCommit().then (commit) -> commit.sha()
  Promise.all [headPromise, headCommitPromise]
  .then (res) ->
    [head, commit] = res
    console.log "HEAD=#{head} - #{commit}"

getUpdatedRepo = (url, branch, path, fetchOptions) ->
  cloneOptions =
    checkoutBranch: branch
    fetchOpts: fetchOptions
 
  Git.Clone(url, path, cloneOptions)
  .catch (e) =>
    console.log "Cannot clone #{url} to #{path}"
    console.log(e)
    console.log 'Fallback: try to open existing git repository'

    Git.Repository.open(path)
    .then (repo) =>
      repository = repo
      console.log 'Open git repository'
      console.log 'Fetch from remotes'
      repository.fetchAll(fetchOptions)
      .then () =>
        console.log "Checkout branch #{branch}"
        repository.checkoutBranch(branch)
      .then () =>
        console.log "Merge from origin"
        repository.mergeBranches(branch, "origin/#{branch}")
      .then () =>
        repository
  .then (repo) =>
    logRepo(repo)
    repo

getCoreVersion = () ->
  pomPath = path + '/pom.xml'
  console.log "Path: #{pomPath}"
  opts =
    filePath: pomPath
  new Promise (res, rej) ->
    pomParser.parse opts, (err, pomResponse) ->
      if (err)
        return rej(err)
      version = pomResponse.pomObject.project.version
      res(version)

module.exports.getUpdatedRepo = getUpdatedRepo
