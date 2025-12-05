using Literate: Literate
using QNSectors

Literate.markdown(
    joinpath(pkgdir(QNSectors), "docs", "files", "README.jl"),
    joinpath(pkgdir(QNSectors), "docs", "src");
    flavor = Literate.DocumenterFlavor(),
    name = "index",
)
