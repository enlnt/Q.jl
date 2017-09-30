J)import Base.Filesystem
J)f = Filesystem.open("/dev/tty", Filesystem.JL_O_RDONLY)
J)eval(Base, :(STDIN = TTY($f.handle; readable=true)))
J)Base._start()
