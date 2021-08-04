using StationXML, Test
using Dates: Date, DateTime

@testset "merge and append" begin
    @testset "_time_ranges_overlap" begin
        cases = (
            # (x.start_date, x.end_date, y.start_date, y.end_date) => correct_answer
            (0, 1, 1, 2) => false,
            (1, 2, 0, 1) => false,
            (0, 1.1, 1, 2) => true,
            (1, 2, 0, 1.1) => true,
            (missing, missing, missing, missing) => true,
            (1, 2, missing, missing) => true,
            (1, missing, missing, missing) => true,
            (missing, 2, missing, missing) => true,
            (missing, 2, 0, missing) => true,
            (missing, 1, 2, missing) => false,
            (missing, 1, missing, 2) => true,
            (1, missing, 2, missing) => true,
            (1, missing, missing, -1) => false,
            (1, missing, missing, 1) => false,
            (missing, 2, 1, 2) => true,
            (missing, 1, 2, 3) => false,
            (1, 2, 3, missing) => false,
            (1, 2, missing, 3) => true
        )
        @testset "$b1 $e1 $b2 $e2" for ((b1, e1, b2, e2), true_or_false) in cases
            @test StationXML._time_ranges_overlap(
                (start_date=b1, end_date=e1), (start_date=b2, end_date=e2)) == true_or_false
            @test StationXML._time_ranges_overlap(
                (start_date=b2, end_date=e2), (start_date=b1, end_date=e1)) == true_or_false
        end
    end

    @testset "merge" begin
        @testset "Identical" begin
            let sxml = gzipped_read("JSA.xml.gz"), sxml′ = deepcopy(sxml)
                @test merge(sxml, sxml) == sxml
                @test merge(sxml, sxml′) == sxml
                @test merge!(sxml, sxml) == sxml
                @test merge!(sxml, sxml′) == sxml
            end
        end

        @testset "Totally different" begin
            let s1 = gzipped_read("JSA.xml.gz"), s2 = gzipped_read("irisws_IU_BHx.xml.gz")
                @test merge(s1, s2) != s1 != s2
                s = merge(s1, s2)
                @test channel_codes(s) == vcat(channel_codes.((s1, s2))...)
                @test all(channels(s) .== vcat(channels.((s1, s2))...))
                @test all(stations(s) .== vcat(stations.((s1, s2))...))
                @test all(networks(s) .== vcat(networks.((s1, s2))...))
                @test merge!(s1, s2) == s
                @test s1 == s
            end
        end

        @testset "Keep first headers" begin
            s1 = gzipped_read("JSA.xml.gz")
            s2 = gzipped_read("orfeus_NL_HGN.xml.gz")
            s = merge(s1, s2)
            for f in filter(x -> x !== :network, fieldnames(typeof(s)))
                # === accounts for missing fields; all are immutables
                @test getfield(s, f) === getfield(s1, f)
                should_equal = getfield(s1, f) === getfield(s2, f)
                @test (getfield(s, f) === getfield(s2, f)) == should_equal
            end
        end

        @testset "Missing from first" begin
            let s1 = gzipped_read("JSA.xml.gz")
                s2 = deepcopy(s1)
                empty!(s1.network)
                @test merge(s1, s2) == s2
                s1 = deepcopy(s2)
                empty!(s1.network[1].station)
                @test merge!(s1, s2) == s2
                empty!(s1.network[1].station[1].channel)
                @test merge(s1, s2) == s2
            end
        end

        @testset "Missing from second" begin
            let s1 = gzipped_read("JSA.xml.gz")
                s2 = deepcopy(s1)
                empty!(s2.network)
                @test merge(s1, s2) == s1
                s2 = deepcopy(s1)
                empty!(s2.network[1].station)
                @test merge(s1, s2) == s1
                s2 = deepcopy(s1)
                empty!(s2.network[1].station[1].channel)
                @test merge(s1, s2) == s1
            end
        end

        @testset "Reusing network codes, different stations" begin
            sxml1 = StationXML.readstring("""
                <?xml version="1.0" encoding="UTF-8"?>
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1" schemaVersion="1.1">
                  <Source>IRIS-DMC</Source>
                  <Created>2021-08-02T14:23:52</Created>
                  <Network code="XM" startDate="2012-01-01T00:00:00" endDate="2014-12-31T23:59:59" restrictedStatus="open">
                    <Description>ARGOS - Alutu and Regional Geophysical Observation Study SEIS-UK (ARGOS)</Description>
                    <Station code="A02E" startDate="2012-01-08T00:00:00" endDate="2013-01-22T23:59:59" restrictedStatus="open">
                      <Latitude datum="WGS84">7.86046</Latitude>
                      <Longitude datum="WGS84">38.799709</Longitude>
                      <Elevation unit="METERS">1643.0</Elevation>
                      <Site>
                        <Name>Abaye Deneba Office</Name>
                      </Site>
                      <CreationDate>2012-01-08T00:00:00</CreationDate>
                      <TotalNumberChannels>3</TotalNumberChannels>
                      <SelectedNumberChannels>1</SelectedNumberChannels>
                      <Channel code="HHZ" startDate="2012-01-08T00:00:00" endDate="2013-01-22T23:59:59" restrictedStatus="open" locationCode="">
                        <Latitude datum="WGS84">7.86046</Latitude>
                        <Longitude datum="WGS84">38.799709</Longitude>
                        <Elevation unit="METERS">1643.0</Elevation>
                        <Depth unit="METERS">0.0</Depth>
                      </Channel>
                    </Station>
                  </Network>
                </FDSNStationXML>
                """)
            sxml2 = StationXML.readstring("""
                <?xml version="1.0" encoding="UTF-8"?>
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1" schemaVersion="1.1">
                  <Source>IRIS-DMC</Source>
                  <Created>2021-08-02T14:23:52</Created>
                  <Network code="XM" startDate="2016-01-01T00:00:00" endDate="2016-12-31T23:59:59" restrictedStatus="open">
                    <Station code="PP02" startDate="2016-03-09T00:00:00" endDate="2016-03-30T23:59:59" restrictedStatus="open">
                      <Latitude datum="WGS84">39.799099</Latitude>
                      <Longitude datum="WGS84">-119.005997</Longitude>
                      <Elevation unit="METERS">1242.4</Elevation>
                      <Site>
                        <Name>Bradys hot spring, NV, USA</Name>
                      </Site>
                      <CreationDate>2016-03-09T00:00:00</CreationDate>
                      <Channel code="DHZ" startDate="2016-03-09T00:00:00" endDate="2016-03-30T23:59:59" restrictedStatus="open" locationCode="">
                        <Latitude datum="WGS84">39.799099</Latitude>
                        <Longitude datum="WGS84">-119.005997</Longitude>
                        <Elevation unit="METERS">1242.4</Elevation>
                        <Depth unit="METERS">0.0</Depth>
                      </Channel>
                    </Station>
                  </Network>
                </FDSNStationXML>
                """)
            sxml = merge(sxml1, sxml2)
            @test length(sxml.network) == 2
            @test channel_codes(sxml) == ["XM.A02E..HHZ", "XM.PP02..DHZ"]
            @test all(networks(sxml) .== vcat(networks.((sxml1, sxml2))...))
        end

        @testset "Reusing different station codes, same network" begin
            sxml1 = dummy_sxml(sta="A", depth=0,
                sta_kwargs=(end_date=DateTime(3000, 1, 1, 23, 59, 59, 999),))
            sxml2 = dummy_sxml(sta="A", depth=100,
                sta_kwargs=(start_date=DateTime(3000, 1, 2),))
            sxml = merge(sxml1, sxml2)
            @test all(stations(sxml) .== vcat(stations.((sxml1, sxml2))...))
        end

        @testset "Channels" begin
            @testset "Nonidentical overlaps" begin
                sxml1 = FDSNStationXML(source="", created=DateTime(3000), schema_version="1.1")
                push!(sxml1.network, StationXML.Network(code="A"))
                kwargs = (longitude=0, latitude=0, elevation=0, code="A")
                site = StationXML.Site("A")
                push!(sxml1.network[1].station, StationXML.Station(; site=site, kwargs...))
                sxml2 = deepcopy(sxml1)
                c1 = StationXML.Channel(; location_code="", depth=0,
                    start_date=DateTime(3000, 1, 1), end_date=DateTime(3000, 1, 3), kwargs...)
                push!(sxml1.network[1].station[1].channel, c1)
                c2 = StationXML.Channel(; location_code="", depth=0,
                    start_date=DateTime(3000, 1, 2), end_date=DateTime(3000, 1, 4), kwargs...)
                push!(sxml2.network[1].station[1].channel, c2)
                @test_logs (:warn, """
                    two channels with code 'A.A..A' overlap in time but are not the same; only keeping the first
                    Time ranges:
                        (DateTime("3000-01-01T00:00:00"), DateTime("3000-01-03T00:00:00"))
                        (DateTime("3000-01-02T00:00:00"), DateTime("3000-01-04T00:00:00"))
                    """
                    ) merge(sxml1, sxml2)
                @test_logs merge(sxml1, sxml2, warn=false)
                @test merge(sxml1, sxml2, warn=false) == sxml1
            end

            @testset "Different channels" begin
                sxml1 = FDSNStationXML(source="", created=DateTime(3000), schema_version="1.1")
                push!(sxml1.network, StationXML.Network(code="A"))
                kwargs = (longitude=0, latitude=0, elevation=0, code="A")
                site = StationXML.Site("A")
                push!(sxml1.network[1].station, StationXML.Station(; site=site, kwargs...))
                sxml2 = deepcopy(sxml1)
                c1 = StationXML.Channel(; location_code="", depth=0,
                    start_date=DateTime(3000, 1, 1), end_date=DateTime(3000, 1, 2), kwargs...)
                push!(sxml1.network[1].station[1].channel, c1)
                c2 = StationXML.Channel(; location_code="", depth=0,
                    start_date=DateTime(3000, 1, 3), end_date=DateTime(3000, 1, 4), kwargs...)
                push!(sxml2.network[1].station[1].channel, c2)
                @test merge(sxml1, sxml2).network[1].station[1].channel == [c1, c2]
                push!(sxml2.network[1].station[1].channel, c1)
                @test merge(sxml1, sxml2).network[1].station[1].channel == [c1, c2]
            end

            @testset "Different locations with overlap" begin
                sxml1 = dummy_sxml(loc="00",
                    cha_kwargs=(start_date=DateTime(3000), end_date=DateTime(3000, 2)))
                sxml2 = dummy_sxml(loc="10",
                    cha_kwargs=(start_date=DateTime(3000, 1, 2), end_date=DateTime(3000, 2, 2)))
                c1 = only(channels(sxml1))
                c2 = only(channels(sxml2))
                @test merge(sxml1, sxml2).network[1].station[1].channel == [c1, c2]
                push!(sxml2.network[1].station[1].channel, c1)
                @test merge(sxml1, sxml2).network[1].station[1].channel == [c1, c2]
            end
        end

        @testset "Three or more objects" begin
            sxmls = [dummy_sxml(sta=sta) for sta in ("A", "B", "C", "D")]
            sxmls′ = deepcopy(sxmls)
            # Order
            @test merge(sxmls...) == merge(merge(sxmls[1:2]...), merge(sxmls[3:end]...))
            @test merge!(sxmls...) == merge(sxmls...)
            # All are merged into first
            @test first(sxmls) == merge(sxmls′...)
            @test first(sxmls) != first(sxmls′)
            # Other elements are not affected
            @test sxmls[2:end] == sxmls′[2:end]
            # Idempotency
            @test merge!(sxmls...) == merge!(sxmls...)
        end
    end

    @testset "append!" begin
        sxml1 = dummy_sxml()
        sxml1′ = deepcopy(sxml1)
        sxml2 = dummy_sxml(net="B")
        append!(sxml1, sxml2)
        @test sxml1 != sxml1′
        @test length(sxml1.network) == 2
        @test sxml1.network[2] == sxml2.network[1]
        append!(sxml1, sxml1)
        @test length(sxml1.network) == 4
        @test sxml1.network[1:2] == sxml1.network[3:4]
        @test sxml1 != sxml1′
    end
end
