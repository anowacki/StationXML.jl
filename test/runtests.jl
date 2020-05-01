using Test

@testset "All tests" begin
    include("accessors.jl")
    include("types.jl")
    include("conversion.jl")
    include("util.jl")
    include("parsing.jl")
    include("io.jl")
end
