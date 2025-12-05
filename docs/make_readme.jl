using Literate: Literate
using QNSectors

Literate.markdown(
    joinpath(pkgdir(QNSectors), "docs", "files", "README.jl"),
    joinpath(pkgdir(QNSectors));
    flavor = Literate.CommonMarkFlavor(),
    name = "README",
)
