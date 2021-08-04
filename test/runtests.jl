using Test


@testset "All tests" begin
    # Defines helper functions and includes tests for these
    include("test_util.jl")

    # The rest are straightforward tests of StationXML
    include("accessors.jl")
    include("types.jl")
    include("conversion.jl")
    include("util.jl")
    include("parsing.jl")
    include("io.jl")
    include("merge.jl")
end
