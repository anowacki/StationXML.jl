# Utility functions for tests

using CodecZlib: GzipDecompressorStream


"Full path to an example StationXML file"
datapath(file) = joinpath(@__DIR__, "data", file)

"Read a Gzipped example file"
gzipped_read(file) = open(datapath(file)) do io
    StationXML.readstring(read(GzipDecompressorStream(io), String))
end
