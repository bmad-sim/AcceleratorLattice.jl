using Pkg 
using Documenter, AcceleratorLattice


makedocs(
  sitename = "AcceleratorLattice.jl",
  authors = "David Sagan",
  format=Documenter.HTMLWriter.HTML(size_threshold = nothing),
  pages = 
  [
    "home" => "index.md",
  ]
)

deploydocs(; repo = "github.com/bmad-sim/AcceleratorLattice.jl.git")
