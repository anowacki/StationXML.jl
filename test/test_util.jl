# Utility functions for tests

using CodecZlib: GzipDecompressorStream
using Dates: Dates
using StationXML: StationXML


"Full path to an example StationXML file"
datapath(file) = joinpath(@__DIR__, "data", file)

"Read a Gzipped example file"
gzipped_read(file) = StationXML.readstring(String(gzipped_read_raw(file)))

"Read a Gzipped example file as a raw set of bytes"
gzipped_read_raw(file) = open(io -> read(GzipDecompressorStream(io)), datapath(file))

"""
    dummy_sxml(; kwargs...) -> ::FDSNStationSXML

Return a dummy minimal `FDSNStationXML` object with a single channel.

# Keyword arguments
- `lon`, `lat`, `elev`, `depth`: Longitude, latitude, elevation and depth used for
  the station and channel.
- `net`, `sta`, `loc`, `cha`: Network, station, location and channel codes.
- `net_kwargs`, `sta_kwargs`, `cha_kwargs`: Extra keyword arguments to pass to the
  `Network`, `Station` and `Channel` constructors, respectively.  These will override
  the default values.
"""
function dummy_sxml(; lon=0, lat=0, elev=0, depth=0, net="XX", sta="YYY", loc="00", cha="ZZZ",
        net_kwargs=(), sta_kwargs=(), cha_kwargs=())
    channel = StationXML.Channel(;
        longitude = lon,
        latitude = lat,
        elevation = elev,
        depth = depth,
        code = cha,
        location_code = loc,
        cha_kwargs...
        )
    station = StationXML.Station(;
        longitude = lon,
        latitude = lat,
        elevation = elev,
        code = sta,
        site = StationXML.Site("Dummy site"),
        channel = [channel],
        sta_kwargs...
        )
    network = StationXML.Network(;
        code = net,
        station = [station],
        net_kwargs...
        )
    StationXML.FDSNStationXML(;
        source = "dummy_sxml",
        created = Dates.now(),
        schema_version = "1.1",
        network = [network]
        )
end

# Tests for the above
@testset "Test utils" begin
    @testset "dummy_sxml" begin
        s = dummy_sxml(lon=1, lat=2, elev=3, depth=4, net="A", sta="B", loc="C", cha="D",
            net_kwargs=(start_date=Dates.DateTime("2012-01-01T"), restricted_status="open"),
            sta_kwargs=(elevation=100, selected_number_channels=1),
            cha_kwargs=(azimuth=180,))
        @test s.source == "dummy_sxml"
        @test s.schema_version == "1.1"
        @test length(s.network) == 1
        net = s.network[1]
        @test net.code == "A"
        @test net.start_date == Dates.DateTime(2012)
        @test net.restricted_status == StationXML.RestrictedStatus("open")
        @test length(net.station) == 1
        sta = net.station[1]
        @test sta.code == "B"
        @test sta.longitude == StationXML.Longitude(1)
        @test sta.latitude == StationXML.Latitude(2)
        @test sta.elevation == StationXML.Distance(100)
        @test sta.selected_number_channels == 1
        @test length(sta.channel) == 1
        cha = sta.channel[1]
        @test cha.code == "D"
        @test cha.location_code == "C"
        @test cha.longitude == StationXML.Longitude(1)
        @test cha.latitude == StationXML.Latitude(2)
        @test cha.elevation == StationXML.Distance(3)
        @test cha.depth == StationXML.Distance(4)
        @test cha.azimuth == StationXML.Azimuth(180)
    end
end
