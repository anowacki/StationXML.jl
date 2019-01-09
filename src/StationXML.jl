module StationXML

using Dates
using Parameters
import EzXML

const M{T} = Union{T,Missing}

include("util.jl")
include("base_types.jl")
include("derived_types.jl")
include("types.jl")
include("io.jl")

end # module
