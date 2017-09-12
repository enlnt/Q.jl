const OS = Dict(:Darwin => 'm', :Linux => 'l')
const QARCH = string(OS[Sys.KERNEL], Sys.WORD_SIZE)
try
  global const QHOME = ENV["QHOME"]
catch
  global const QHOME = joinpath(homedir(), "q")
end
const EMBED_DIR = joinpath(@__DIR__, "..", "embed")
if isdir(joinpath(QHOME, QARCH))
  run(`make -C $(EMBED_DIR) QHOME=$(QHOME) QARCH=$(QARCH) install`)
  run(`make -C $(EMBED_DIR) QHOME=$(QHOME) QARCH=$(QARCH) clean`)
  info("Installed server components for $(QARCH) in $(QHOME).")
else
  warn("Could not find a suitable kdb+ installation.",
       "\nServer components are not installed.")
end
