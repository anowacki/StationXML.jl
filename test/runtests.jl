using Test

@testset "All tests" begin
    include("io.jl")
    include("accessors.jl")
    include("constructors.jl")
    include("util.jl")
    include("parsing.jl")
end
