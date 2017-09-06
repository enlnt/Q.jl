println("Building Q...")
const OS = Dict(:Darwin => 'm', :Linux => 'l')
QARCH = string(OS[Sys.KERNEL], Sys.WORD_SIZE)
QHOME = get(ENV, "QHOME", "")
if QHOME == ""
  QHOME = joinpath(homedir(), "q")
end
EMBED_DIR = joinpath(@__DIR__, "..", "embed")
if isdir(joinpath(QHOME, QARCH))
  run(`make -C $(EMBED_DIR) QHOME=$(QHOME) QARCH=$(QARCH) install`)
  println("Installed server components for $(QARCH) in $(QHOME).")
else
  println("Could not find a suitable kdb+ installation.")
  println("Server components are not installed")
end
