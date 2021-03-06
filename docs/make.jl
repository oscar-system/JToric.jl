push!(LOAD_PATH,"../src/")
using Documenter, JToric, DocumenterMarkdown

# ensure JToric is loaded for the doc tests
DocMeta.setdocmeta!(JToric, :DocTestSetup, :(using JToric, Random; using JToric.Oscar); recursive = true)

makedocs(sitename="JToric -- Toric Geometry in Julia")

deploydocs(repo = "github.com/oscar-system/JToric.jl.git")
