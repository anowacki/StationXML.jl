using StationXML, Test
import Dates

# Example StationXML file
datafile = joinpath("..", "data", "JSA.xml")

@testset "I/O" begin
    @testset "Read(string)" begin
        let str = String(read(datafile))
            @test StationXML.read(datafile) == StationXML.readstring(str)
        end
    end

    @testset "Read" begin
        let badstring = """
            <?xml version="1.0" encoding="UTF8"?>
            <SomeWeirdThing xmlns="http://www.fdsn.org/xml/station/1">
            </SomeWeirdThing>
            """
            @test_throws ArgumentError StationXML.readstring(badstring)
        end
        let sxml = StationXML.read(datafile)
            @test typeof(sxml) == FDSNStationXML
            @test sxml.source == sxml.sender == "IRIS-DMC"
            @test sxml.module_name == "IRIS WEB SERVICE: fdsnws-station | version: 1.1.36"
            @test sxml.schema_version == "1.0"
            @test length(sxml.network) == 1
            @test length(sxml.network[1].station) == 1
            @test length(sxml.network[1].station[1].channel) == 6
            @test ismissing(sxml.network[1].historical_code)
            @test sxml.network[1].station[1].site.name == "ST AUBINS, JERSEY"
            @test sxml.network[1].station[1].start_date == Dates.DateTime(2007, 09, 06, 0, 0, 0)
        end
    end
end
