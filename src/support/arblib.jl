#   Set up environment / load libraries
#   (from Nemo.jl)

using Libdl
using LoadFlint
using Pkg

if VERSION > v"1.3.0-rc4"
  # this should do the dlopen for 1.3 and later
  # and imports the libxxx variables
  using Arb_jll
else
  deps_dir = joinpath(@__DIR__, "..", "deps")
  include(joinpath(deps_dir,"deps.jl"))
end

iswindows64() = (Sys.iswindows() ? true : false) && (Int == Int64)

const pkgdir = realpath(joinpath(dirname(@__DIR__)))

#const libdir = joinpath(pkgdir, "deps", "usr", "lib")
#const bindir = joinpath(pkgdir, "deps", "usr", "bin")

const libFlint = LoadFlint.libflint
const libGMP = LoadFlint.libgmp
const libMPFR = LoadFlint.libmpfr

macro libarb(libraryfunction)
    (:($libraryfunction), LibArb)
end

macro libflint(libraryfunction)
    (:($libraryfunction), LibFlint)
end



#=
macro libgmp(libraryfunction)
    (:($libraryfunction), LibGMP)
end

macro libmpfr(libraryfunction)
    (:($libraryfunction), LibMPFR)
end
=#

