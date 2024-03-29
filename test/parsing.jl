using StationXML, Test
using Dates: DateTime
import EzXML

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
                """).created == DateTime(2019, 04, 1, 10, 58, 21, 123)
            # Time zone ahead of UTC
            @test StationXML.readstring("""
                <?xml version="1.0" encoding="UTF-8"?>
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1" schemaVersion="1.0">
                  <Source>StationXML.jl</Source>
                  <Sender>Test</Sender>
                  <Created>2000-01-01T12:34:00.123456789-12:34</Created>
                </FDSNStationXML>
                """).created == DateTime(2000, 1, 1, 0, 0, 0, 123)
            # UTC specified
            @test StationXML.readstring("""
                <?xml version="1.0" encoding="UTF-8"?>
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1" schemaVersion="1.0">
                  <Source>StationXML.jl</Source>
                  <Sender>Test</Sender>
                  <Created>2019-04-01T09:58:21Z</Created>
                </FDSNStationXML>
                """).created == DateTime(2019, 04, 1, 9, 58, 21)
            # Invalid format throws a helpful error
            for dtstring in ("2000", "2000-01", "2000-01-01", "2000-01-01T",
                    "2000-01-01T00", "2000-01-01T00:00")
                node = EzXML.parsexml("<element>$dtstring</element>").root
                @test_throws ArgumentError StationXML.parse_node(DateTime, node)
            end
            # Dates in attributes
            @test StationXML.readstring("""
                <?xml version='1.0' encoding='UTF-8'?>
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1" schemaVersion="1.1">
                  <Source>SeisComP3</Source>
                  <Sender>ODC</Sender>
                  <Module/>
                  <ModuleURI/>
                  <Created>2020-04-28T21:17:08.868852Z</Created>
                  <Network code="NL" startDate="1993-01-01T00:00:00.987654Z" restrictedStatus="open">
                    <Description>Netherlands Seismic and Acoustic Network</Description>
                  </Network>
                </FDSNStationXML>
                """).network[1].start_date == DateTime(1993, 1, 1, 0, 0, 0, 987)
        end
    end

    @testset "Required fields" begin
        @testset "Missing source" begin
            @test_throws UndefVarError StationXML.readstring("""
                <?xml version="1.0" encoding="UTF-8"?>
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1" schemaVersion="1.1">
                  <Created>2000-01-01T12:34:00.123456789-12:34</Created>
                </FDSNStationXML>
                """)
        end
        @testset "Missing network code" begin
            @test_throws UndefVarError StationXML.readstring("""
                <?xml version="1.0" encoding="UTF-8"?>
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1" schemaVersion="1.1">
                  <Created>2000-01-01T12:34:00.123456789-12:34</Created>
                  <Source>Test</Source>
                  <Network>
                  </Network>
                </FDSNStationXML>
                """)
        end
        @testset "Missing station latitude" begin
            @test_throws UndefVarError StationXML.readstring("""
                <?xml version="1.0" encoding="UTF-8"?>
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1" schemaVersion="1.1">
                  <Created>2000-01-01T12:34:00.123456789-12:34</Created>
                  <Source>Test</Source>
                  <Network code="XX">
                    <Station code="YYY">
                      <Longitude>0</Longitude>
                      <Elevation>0</Elevation>
                      <Site>
                        <Name>Example site</Name>
                      </Site>
                    </Station>
                  </Network>
                </FDSNStationXML>
                """)
        end
    end


    # Changes from v1.0 to v1.1
    @testset "Version 1.1" begin
        let sxml = StationXML.readstring("""
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1"
                  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                  xmlns:iris="http://www.fdsn.org/xml/station/1/iris"
                  xsi:schemaLocation="http://www.fdsn.org/xml/station/1 http://www.fdsn.org/xml/station/fdsn-station-1.1.xsd"
                  schemaVersion="1.1">
                 <Source>IRIS-DMC</Source>
                 <Sender>IRIS-DMC</Sender>
                 <Module>IRIS WEB SERVICE: fdsnws-station | version: 1.1.45</Module>
                 <ModuleURI>http://service.iris.edu/fdsnws/station/1/query?nodata=204</ModuleURI>
                 <Created>2020-05-05T19:13:31</Created>
                 <Network code="1B" startDate="2014-01-01T00:00:00" endDate="2014-12-31T23:59:59"
                   restrictedStatus="open" sourceID="mailto:net@example.com">
                  <Description>Sweetwater Array (1B)</Description>
                  <TotalNumberStations>2268</TotalNumberStations>
                  <Identifier type="some type">Identifying text</Identifier>
                  <Identifier type="another type">More text</Identifier>
                  <SelectedNumberStations>2268</SelectedNumberStations>
                  <Station code="5R536" startDate="2014-01-01T00:00:00"
                    endDate="2014-12-12T23:59:59" restrictedStatus="open"
                    sourceID="https://example.com"
                    iris:alternateNetworkCodes=".UNRESTRICTED">
                   <DataAvailability>
                    <Extent start="2000-01-01T00:00:00.000999Z" end="3000-01-01T00:00:00">
                    </Extent>
                    <Span start="1990-01-01T00:00:00" end="1991-01-01T00:00:00" numberSegments="2"
                     maximumTimeTear="0.1"/>
                   </DataAvailability>
                   <Identifier>ID</Identifier>
                   <Latitude>32.748402</Latitude>
                   <Longitude>-100.535698</Longitude>
                   <Elevation>634.7</Elevation>
                   <Site>
                    <Name>207536</Name>
                   </Site>
                   <TotalNumberChannels>1</TotalNumberChannels>
                   <SelectedNumberChannels>1</SelectedNumberChannels>
                   <Channel code="SXZ" locationCode="00">
                    <Identifier type="A">B</Identifier>
                    <Latitude>1</Latitude>
                    <Longitude>2</Longitude>
                    <Elevation>3</Elevation>
                    <Depth>4</Depth>
                   </Channel>
                  </Station>
                 </Network>
                </FDSNStationXML>
                """)
            @test sxml.schema_version == "1.1"
            @testset "Add Identifier" begin
                @test length(sxml.network[1].identifier) == 2
                @test sxml.network[1].identifier[1].value == "Identifying text"
                @test sxml.network[1].identifier[1].type == "some type"
                @test sxml.network[1].identifier[2].value == "More text"
                @test sxml.network[1].identifier[2].type == "another type"
                @test length(sxml.network[1].station[1].identifier) == 1
                @test sxml.network[1].station[1].identifier[1].value == "ID"
                @test sxml.network[1].station[1].identifier[1].type === missing
                @test sxml.network[1].station[1].channel[1].identifier[1].value == "B"
                @test sxml.network[1].station[1].channel[1].identifier[1].type == "A"
            end
            @testset "Optional CreationDate" begin
                @test sxml.network[1].station[1].creation_date === missing
            end
            @testset "Add sourceID" begin
                @test sxml.network[1].source_id == "mailto:net@example.com"
                @test sxml.network[1].station[1].source_id == "https://example.com"
                @test sxml.network[1].station[1].channel[1].source_id === missing
            end
            @testset "Add DataAvailability" begin
                @test sxml.network[1].station[1].data_availability.extent.start == DateTime(2000)
                @test sxml.network[1].station[1].data_availability.extent.end_ == DateTime(3000)
                @test sxml.network[1].station[1].data_availability.span[1].start == DateTime(1990)
                @test sxml.network[1].station[1].data_availability.span[1].end_ == DateTime(1991)
                @test sxml.network[1].station[1].data_availability.span[1].number_segments == 2
                @test sxml.network[1].station[1].data_availability.span[1].maximum_time_tear == 0.1
            end
        end
    end

    @testset "Pressure channel" begin
        let node = EzXML.root(EzXML.parsexml("""
                <Channel code="LDO" locationCode="00" startDate="2008-10-10T00:00:00" restrictedStatus="open">
                 <Latitude>10.00207</Latitude>
                 <Longitude>-84.111389</Longitude>
                 <Elevation>1186</Elevation>
                 <Depth>0</Depth>
                 <Azimuth>0</Azimuth>
                 <Dip>0</Dip>
                 <Type>CONTINUOUS</Type>
                 <Type>WEATHER</Type>
                 <SampleRate>1E00</SampleRate>
                 <ClockDrift>1E-04</ClockDrift>
                 <Sensor>
                  <Description>Microbaro VAISALA</Description>
                 </Sensor>
                 <Response>
                 <InstrumentSensitivity>
                   <InputUnits>
                     <Name>PA</Name>
                     <Description>PRESSURE in Pascals</Description>
                   </InputUnits>
                   <OutputUnits>
                     <Name>COUNTS</Name>
                     <Description>DIGITAL UNIT in Counts</Description>
                   </OutputUnits>
                 </InstrumentSensitivity>
                 </Response>
                </Channel>
                """))
            channel = StationXML.parse_node(StationXML.Channel, node)
            @test channel.response.instrument_sensitivity.value === missing
            @test channel.response.instrument_sensitivity.input_units.name == "PA"
        end
    end
end