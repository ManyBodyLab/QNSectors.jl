using QNSectors
using Documenter: Documenter, DocMeta, deploydocs, makedocs

DocMeta.setdocmeta!(
    QNSectors, :DocTestSetup, :(using QNSectors); recursive = true
)

include("make_index.jl")

makedocs(;
    modules = [QNSectors],
    authors = "Andreas Feuerpfeil <development@manybodylab.com>",
    sitename = "QNSectors.jl",
    format = Documenter.HTML(;
        canonical = "https://manybodylab.github.io/QNSectors.jl",
        edit_link = "main",
        assets = [#"assets/logo.png", 
            "assets/extras.css"],
    ),
    pages = ["Home" => "index.md", "Reference" => "reference.md"],
)

deploydocs(;
    repo = "github.com/ManyBodyLab/QNSectors.jl", devbranch = "main", push_preview = true
)
