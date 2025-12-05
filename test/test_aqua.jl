using QNSectors
using Aqua: Aqua
using Test

@testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(QNSectors)
end
