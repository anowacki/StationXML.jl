using StationXML, Test

@testset "Parsing" begin
    @testset "Dates" begin
        let
            # Time zone and too much precision
            @test StationXML.readstring("""
                <?xml version="1.0" encoding="UTF-8"?>
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1" schemaVersion="1.0">
                  <Source>StationXML.jl</Source>
                  <Sender>Test</Sender>
                  <Created>2019-04-01T09:58:21.123456789+01:00</Created>
                </FDSNStationXML>
                """).created == Dates.DateTime(2019, 04, 1, 10, 58, 21, 123)
            # Time zone ahead of UTC
            @test StationXML.readstring("""
                <?xml version="1.0" encoding="UTF-8"?>
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1" schemaVersion="1.0">
                  <Source>StationXML.jl</Source>
                  <Sender>Test</Sender>
                  <Created>2000-01-01T12:34:00.123456789-12:34</Created>
                </FDSNStationXML>
                """).created == Dates.DateTime(2000, 1, 1, 0, 0, 0, 123)
            # UTC specified
            @test StationXML.readstring("""
                <?xml version="1.0" encoding="UTF-8"?>
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1" schemaVersion="1.0">
                  <Source>StationXML.jl</Source>
                  <Sender>Test</Sender>
                  <Created>2019-04-01T09:58:21Z</Created>
                </FDSNStationXML>
                """).created == Dates.DateTime(2019, 04, 1, 9, 58, 21)

        end
    end
end