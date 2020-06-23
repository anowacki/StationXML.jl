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
        end
    end

    @testset "Version 1.1" begin
        # Optional CreationDate for Station
        let sxml = StationXML.readstring("""
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:iris="http://www.fdsn.org/xml/station/1/iris" xsi:schemaLocation="http://www.fdsn.org/xml/station/1 http://www.fdsn.org/xml/station/fdsn-station-1.1.xsd" schemaVersion="1.1">
                 <Source>IRIS-DMC</Source>
                 <Sender>IRIS-DMC</Sender>
                 <Module>IRIS WEB SERVICE: fdsnws-station | version: 1.1.45</Module>
                 <ModuleURI>http://service.iris.edu/fdsnws/station/1/query?nodata=204</ModuleURI>
                 <Created>2020-05-05T19:13:31</Created>
                 <Network code="1B" startDate="2014-01-01T00:00:00" endDate="2014-12-31T23:59:59" restrictedStatus="open">
                  <Description>Sweetwater Array (1B)</Description>
                  <TotalNumberStations>2268</TotalNumberStations>
                  <SelectedNumberStations>2268</SelectedNumberStations>
                  <Station code="5R536" startDate="2014-01-01T00:00:00" endDate="2014-12-12T23:59:59" restrictedStatus="open" iris:alternateNetworkCodes=".UNRESTRICTED">
                   <Latitude>32.748402</Latitude>
                   <Longitude>-100.535698</Longitude>
                   <Elevation>634.7</Elevation>
                   <Site>
                    <Name>207536</Name>
                   </Site>
                   <TotalNumberChannels>1</TotalNumberChannels>
                   <SelectedNumberChannels>0</SelectedNumberChannels>
                  </Station>
                 </Network>
                </FDSNStationXML>
                """)
            @test sxml.schema_version == "1.1"
            @test sxml.network[1].station[1].creation_date === missing
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