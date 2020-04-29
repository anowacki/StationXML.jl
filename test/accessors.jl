using StationXML, Test

include("test_util.jl")

let sxml = gzipped_read("JSA.xml.gz")
    @testset "Accessors" begin
        @testset "Functions" begin
            @test networks(sxml) == sxml.network
            @test length(networks(sxml)) == 1
            @test stations(sxml) == [s for s in Iterators.flatten(net.station for net in networks(sxml))]
            @test [s.code for s in stations(sxml)] == ["JSA"]
            @test length(stations(sxml)) == 1
            @test channels(sxml) == [c for c in Iterators.flatten(sta.channel for sta in stations(sxml))]
            @test [c.code for c in channels(sxml)] == ["BHE", "BHN", "BHZ", "HHE", "HHN", "HHZ"]
            @test length(channels(sxml)) == 6
            @test stations(sxml) == stations(networks(sxml)[1])
            @test channels(sxml) == channels(networks(sxml)[1]) ==
                      channels(stations(sxml)[1]) == channels(stations(networks(sxml)[1])[1])
        end

        @testset "Getproperty" begin
            @test sxml.network.code == ["GB"]
            @test typeof(sxml.network.station) == Vector{Vector{StationXML.Station}}
            @test [s.code for net in sxml.network for s in net.station] == ["JSA"]
            @test stations(sxml).code == ["JSA"]
            @test channels(sxml).code == ["BHE", "BHN", "BHZ", "HHE", "HHN", "HHZ"]
        end

        @testset "Channel codes" begin
            @test channel_codes(sxml) == channel_codes(sxml.network[1])
            @test channel_codes(sxml) == ["GB.JSA..BHE", "GB.JSA..BHN", "GB.JSA..BHZ", "GB.JSA..HHE", "GB.JSA..HHN", "GB.JSA..HHZ"]
        end
    end
end
