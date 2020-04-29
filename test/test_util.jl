# Utility functions for tests

using CodecZlib: GzipDecompressorStream


"Full path to an example StationXML file"
datapath(file) = joinpath(@__DIR__, "data", file)

"Read a Gzipped example file"
gzipped_read(file) = StationXML.readstring(String(gzipped_read_raw(file)))

"Read a Gzipped example file as a raw set of bytes"
gzipped_read_raw(file) = open(io -> read(GzipDecompressorStream(io)), datapath(file))
