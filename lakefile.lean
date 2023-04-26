import Lake
open Lake DSL System

package «Polyscope» {
  -- add package configuration options here
}

lean_lib «Polyscope» {
  -- add library configuration options here
}

lean_exe «PolyscopeExamples» {
  root := `Examples
}

/- How do I get this from ProofWidgets4? -/
/-! Widget build -/
def npmCmd : String :=
  if Platform.isWindows then "npm.cmd" else "npm"

def widgetDir := __dir__ / "widget"

target widgetPackageLock : FilePath := do
  let packageFile ← inputFile <| widgetDir / "package.json"
  let packageLockFile := widgetDir / "package-lock.json"
  buildFileAfterDep packageLockFile packageFile fun _srcFile => do
    proc {
      cmd := npmCmd
      args := #["install"]
      cwd := some widgetDir
    }

def widgetTsxTarget (pkg : Package) (tsxName : String) (deps : Array (BuildJob FilePath))
    (isDev : Bool)
    [Fact (pkg.name = _package.name)] : IndexBuildM (BuildJob FilePath) := do
  let jsFile := pkg.buildDir / "js" / s!"{tsxName}.js"
  let deps := deps ++ #[
    ← inputFile <| widgetDir / "src" / s!"{tsxName}.tsx",
    ← inputFile <| widgetDir / "rollup.config.js",
    ← inputFile <| widgetDir / "tsconfig.json"
    -- , ← fetch (pkg.target ``widgetPackageLock)
  ]
  buildFileAfterDepArray jsFile deps fun _srcFile => do
    IO.println s!"building {jsFile}..."
    proc {
      cmd := npmCmd
      args :=
        if isDev then
          #["run", "build-dev", "--", "--tsxName", tsxName]
        else
          #["run", "build", "--", "--tsxName", tsxName]
      cwd := some widgetDir
    }

def widgetJsAllTarget (pkg : Package) [Fact (pkg.name = _package.name)] (isDev : Bool) :
    IndexBuildM (BuildJob (Array FilePath)) := do
  -- installDeps isDev
  let fs ← (widgetDir / "src").readDir
  let tsxs : Array FilePath := fs.filterMap fun f =>
    let p := f.path; if let some "tsx" := p.extension then some p else none
  -- Conservatively, every .js build depends on all the .tsx source files.
  let deps ← liftM <| tsxs.mapM inputFile
  let jobs ← tsxs.mapM fun tsx => widgetTsxTarget pkg tsx.fileStem.get! deps isDev
  BuildJob.collectArray jobs


target widgetJsAll (pkg : Package) : Array FilePath := do
  widgetJsAllTarget pkg (isDev := false)

target widgetJsAllDev (pkg : Package) : Array FilePath := do
  widgetJsAllTarget pkg (isDev := true)


require proofwidgets from git "https://github.com/EdAyers/ProofWidgets4"@"v0.0.5"

meta if get_config? env = some "dev" then -- dev is so not everyone has to build it
  require «doc-gen4» from git "https://github.com/leanprover/doc-gen4" @ "b9421b9"

@[default_target]
target all (pkg : Package) : Unit := do
  let some lib := pkg.findLeanLib? ``Polyscope |
    error "cannot find lib Polyscope"
  let some exe := pkg.findLeanExe? ``PolyscopeExamples |
    error "cannot find exe PolyscopeExamples"
  let job ← fetch (pkg.target ``widgetJsAll)
  let _ ← job.await
  let job ← lib.recBuildLean
  let _ ← job.await
  let job ← exe.recBuildExe
  let _ ← job.await
  return .nil
