# Release procedure
## References
 * [Julia Package Development Kit (PkgDev)](https://github.com/JuliaLang/PkgDev.jl)
 * [Making Your Package Available (Julia manual)](https://docs.julialang.org/en/stable/manual/packages/#Making-Your-Package-Available-1)
 * [AttoBot (a package release bot)](https://github.com/attobot/attobot)
 * [Creating Releases (Github Help)](https://help.github.com/articles/creating-releases)
 
 ## Steps
 
 Create a fresh clone
 
```
julia> Pkg.clone("git@github.com:enlnt/Q.jl.git")
INFO: Cloning Q from git@github.com:enlnt/Q.jl.git
..
```

Run client tests

```
$ julia
julia> Pkg.test("Q")
INFO: Testing Q
Test Summary: | Pass  Total
Q tests       |  344    344
INFO: Q tests passed
```

Run server tests

```
$ cd $(julia -e 'println(Pkg.dir("Q"))')
$ $QHOME/julia.q test/runtests.jl -q
Test Summary: | Pass  Total
Q tests       |  369    369
```

Follow [Github release procedure](https://help.github.com/articles/creating-releases)
