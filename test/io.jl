using StationXML, Test
using Dates: DateTime
import EzXML

@testset "I/O" begin
    @testset "Read(string)" begin
        let file = datapath("JSA.xml"), str = String(read(file))
            @test StationXML.read(file) == StationXML.readstring(str)
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
        # GB.JSA from IRIS
        let sxml = gzipped_read("JSA.xml.gz")
            @test typeof(sxml) == FDSNStationXML
            @test sxml.source == sxml.sender == "IRIS-DMC"
            @test sxml.module_name == "IRIS WEB SERVICE: fdsnws-station | version: 1.1.36"
            @test sxml.schema_version == "1.0"
            @test length(sxml.network) == 1
            @test length(sxml.network[1].station) == 1
            @test length(sxml.network[1].station[1].channel) == 6
            @test ismissing(sxml.network[1].historical_code)
            @test sxml.network[1].station[1].site.name == "ST AUBINS, JERSEY"
            @test sxml.network[1].station[1].start_date == DateTime(2007, 09, 06, 0, 0, 0)
            # Channel
            bhe = channels(sxml)[1]
            @test bhe.latitude.value ≈ 49.187801
            @test bhe.longitude.value ≈ -2.171698
            @test bhe.elevation.value ≈ 39.0
            @test bhe.depth.value ≈ 0.0 atol=1e-5
            @test bhe.azimuth.value ≈ 90.0
            @test bhe.dip.value ≈ 0.0 atol=1e-5
            @test bhe.clock_drift.value ≈ 0.0 atol=1e-5
            @test bhe.calibration_units.name == "A"
            @test bhe.calibration_units.description == "Amperes"
            @test bhe.restricted_status.value == "open"
            # Response
            @test bhe.response isa StationXML.Response
            @test !ismissing(bhe.response.instrument_sensitivity)
            @test ismissing(bhe.response.instrument_polynomial)
            @test length(bhe.response.stage) == 6
            @test count(!ismissing, getfield.((bhe.response.stage[1],),
                (:poles_zeros, :coefficients, :response_list, :fir, :polynomial))) == 1
            pz = bhe.response.stage[1].poles_zeros
            @test !ismissing(pz)
            @test pz.input_units.name == "M/S"
            @test pz.output_units.name == "V"
            @test pz.pz_transfer_function_type == StationXML.PZTransferFunction("LAPLACE (RADIANS/SECOND)")
            @test pz.normalization_factor ≈ 2.31323e9
            @test pz.normalization_frequency ≈ 1.0
            @test length(pz.zero) == 4
            @test length(pz.pole) == 7
            @test [p.real.value for p in pz.pole] ≈ [-0.01815, -0.01815, -196.0, -196.0, -732.0, -732.0, -173.0]
            @test [p.imaginary.value for p in pz.pole] ≈ [0.01799, -0.01799, 231.0, -231.0, 1415.0, -1415.0, 0.0]
            cf = bhe.response.stage[2].coefficients
            @test !ismissing(cf)
            @test cf.input_units.name == pz.output_units.name == "V"
            @test cf.output_units.name == "COUNTS"
            @test cf.cf_transfer_function_type == StationXML.CfTransferFunction("DIGITAL")
            @test length(cf.numerator) == length(cf.denominator) == 0
            dec = bhe.response.stage[2].decimation
            @test !ismissing(dec)
            @test dec.input_sample_rate.value ≈ 30_000.0
            @test dec.factor ≈ 1.0
            @test dec.offset ≈ 0.0 atol=1e-5
            @test dec.delay ≈ 0.0 atol=1e-5
            @test dec.correction ≈ 0.0 atol=1e-5
            @test bhe.response.stage[2].stage_gain.value ≈ 400_000.0
            @test bhe.response.stage[2].stage_gain.frequency ≈ 0.0 atol=1e-5
        end
        # NL.HGN from Orfeus
        let sxml = gzipped_read("orfeus_NL_HGN.xml.gz")
            @test sxml.schema_version == "1.0"
            @test sxml.source == "SeisComP3"
            @test sxml.sender == "ODC"
            @test sxml.created == DateTime(2020, 4, 28, 21, 17, 08, 868)
            @test length(sxml.network) == 1
            net = first(sxml.network)
            @test net.code == "NL"
            @test net.restricted_status == StationXML.RestrictedStatus("open")
            @test net.start_date == DateTime(1993)
            @test net.description == "Netherlands Seismic and Acoustic Network"
            @test length(net.station) == 1
            sta = first(net.station)
            @test sta.code == "HGN"
            @test sta.restricted_status == StationXML.RestrictedStatus("open")
            @test sta.start_date == DateTime(2001, 06, 06)
            @test sta.latitude.value == 50.764
            @test sta.latitude.plus_error === missing
            @test sta.latitude.minus_error === missing
            @test sta.latitude.unit === missing
            @test sta.latitude.datum == "WGS84"
            @test sta.longitude.value == 5.9317
            @test sta.longitude.plus_error === missing
            @test sta.longitude.minus_error === missing
            @test sta.longitude.unit === missing
            @test sta.longitude.datum == "WGS84"
            @test length(sta.channel) == 12
            cha = first(sta.channel)
            @test cha.end_date == DateTime(2003, 10, 24)
            @test cha.longitude == sta.longitude
            @test cha.latitude == sta.latitude
            @test cha.elevation == sta.elevation
            @test cha.dip.value == 0
            @test cha.dip.plus_error === missing
            @test cha.dip.minus_error === missing
            @test cha.dip.unit === missing
            @test cha.sample_rate.value == 40
            @test cha.sample_rate.unit === missing
            @test cha.sample_rate_ratio.number_samples == 40
            @test cha.sample_rate_ratio.number_seconds == 1
            @test cha.sensor.resource_id == "Sensor#20140909071419.913703.12"
            @test cha.sensor.type == "STS-1"
            @test cha.sensor.description == "STS-1"
            @test cha.sensor.model == "STS-1"
            @test cha.data_logger.resource_id == "Datalogger#20140909071419.913633.11"
            @test cha.data_logger.description == "HGN.1993.307.BHE"
            resp = cha.response
            @test resp.instrument_sensitivity.value == 801102000
            @test resp.instrument_sensitivity.frequency == 1
            @test resp.instrument_sensitivity.input_units == StationXML.Units("M/S")
            @test resp.instrument_sensitivity.output_units == StationXML.Units("COUNTS")
            @test length(resp.stage) == 2
            stage1 = resp.stage[1]
            @test stage1.number == 1
            @test stage1.poles_zeros !== missing
            @test stage1.stage_gain.value == 801102000
            @test stage1.stage_gain.frequency == 1
            pz = stage1.poles_zeros
            @test pz.name == "HGN.1993.307.HE"
            @test pz.resource_id == "ResponsePAZ#20140909071419.91376.13"
            @test pz.input_units == StationXML.Units("M/S")
            @test pz.output_units == StationXML.Units("V")
            @test pz.pz_transfer_function_type == StationXML.PZTransferFunction("LAPLACE (RADIANS/SECOND)")
            @test pz.normalization_factor == 3.86603e12
            @test pz.normalization_frequency == 1
            @test [p.real.value for p in pz.pole] == [-0.01234, -0.01234, -62.832,
                -39.144, -39.144, -14.012, -14.012, -56.612, -56.612]
            @test [p.imaginary.value for p in pz.pole] == [0.01234, -0.01234, 0,
                49.148, -49.148, 61.25, -61.25, 27.258, -27.258]
            @test [(z.real.value, z.imaginary.value) for z in pz.zero] ==
                [(0.0, 0.0), (0.0, 0.0)]
            @test [p.number for p in pz.pole] == 0:8
            @test [z.number for z in pz.zero] == 9:10
            @test all(x -> x===missing, p.real.plus_error for p in pz.pole)
            stage2 = resp.stage[2]
            @test stage2.number == 2
            @test stage2.coefficients !== missing
            @test stage2.decimation !== missing
            coefs = stage2.coefficients
            @test coefs.input_units == StationXML.Units("V")
            @test coefs.output_units == StationXML.Units("COUNTS")
            @test coefs.cf_transfer_function_type == StationXML.CfTransferFunction("DIGITAL")
            @test isempty(coefs.numerator)
            @test isempty(coefs.denominator)
            dec = stage2.decimation
            @test dec.input_sample_rate == StationXML.Frequency(40)
            @test dec.factor == 1
            @test dec.offset == 0
            @test dec.delay == 0
            @test dec.correction == 0

            # NL.HGN.02.BHZ
            cha = last(sta.channel)
            @test cha.code == "BHZ"
            @test cha.location_code == "02"
            @test cha.start_date == DateTime(2009, 4, 27)
            @test cha.dip == StationXML.Dip(-90)
            @test length(cha.response.stage) == 3
            stage3 = last(cha.response.stage)
            @test stage3.fir !== missing
            fir = stage3.fir
            @test fir.input_units == fir.output_units == StationXML.Units("COUNTS")
            @test fir.symmetry == StationXML.FIRSymmetry("NONE")
            @test length(fir.numerator_coefficient) == 39
            @test fir.numerator_coefficient == [StationXML.NumeratorCoefficient(c, missing)
                for c in [-5.09997e-08, -2.63324e-08, 3.21041e-07, -1.2548e-05,
                          -1.56874e-06, 0.000633072, 0.000467293, -0.00375769,
                          0.00242649, -0.00181103, -0.00255789, 0.00852735,
                          -0.0154895, 0.0199414, -0.0183877, 0.00706362, 0.0161458,
                          -0.0509218, 0.095284, -0.166693, 0.266723, 0.837233,
                          0.0500619, -0.0891913, 0.0853716, -0.0651036, 0.0395074,
                          -0.0158729, -0.00144455, 0.0107821, -0.0131202, 0.0104801,
                          -0.00623193, 0.00152521, 0.000205709, -0.00314123, 0.00102921,
                          0.000330318, 4.18952e-13]]

            @testset "No InutUnits" begin
                sxml = gzipped_read("irisws_XA_no_input_units.xml.gz")
                @test sxml.network[1].station[1].channel[1].response.instrument_sensitivity.input_units === missing
            end
        end
    end

    @testset "Schema version" begin
        # Version 1
        for version in ("v1.0", "v1.1", "v1.1.2", "v1.2", "v1.99")
            str = """
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1" schemaVersion="$version">
                  <Source>StationXML.jl</Source>
                  <Sender>Test</Sender>
                  <Created>2019-04-01T09:58:21.123456789+01:00</Created>
                </FDSNStationXML>
                """
            xml = EzXML.parsexml(str)
            if version in ("v1.0", "v1.1", "v1.1.2")
                @test StationXML.schema_version_is_okay(xml)
            else
                @test (@test_logs (:warn,
                    "document is StationXML version $(VersionNumber(version)); " *
                    "only v1.1 data will be read") StationXML.schema_version_is_okay(xml))
            end
        end
        # Version 2+
        @test !StationXML.schema_version_is_okay(EzXML.parsexml("""
            <FDSNStationXML schemaVersion="2.0">
              <Source>StationXML.jl</Source>
              <Sender>AN</Sender>
              <Created>3000-01-01T00:00:00.00</Created>
            </FDSNStationXML>
            """))
    end

    @testset "Writing strings" begin
        let sxml = FDSNStationXML(source="StationXML.jl",
                created=DateTime(3000), schema_version=StationXML.DEFAULT_SCHEMA_VERSION), xml=xmldoc(sxml)
            push!(sxml.network, StationXML.Network(code="AN"))
            @test string(xml) == """
                <?xml version="1.0" encoding="UTF-8"?>
                <FDSNStationXML xmlns="http://www.fdsn.org/xml/station/1" schemaVersion="1.1"><Source>StationXML.jl</Source><Created>3000-01-01T00:00:00</Created></FDSNStationXML>
                """
        end
    end

    @testset "Writing" begin
        filenames = ("irisws_AK.xml.gz", "irisws_IU_BHx.xml.gz", "JSA.xml.gz",
            "orfeus_NL_HGN.xml.gz")

        @testset "To file" begin
            let sxml = sxml = FDSNStationXML(source="AN",
                    created=DateTime("2000-01-01"), schema_version=StationXML.DEFAULT_SCHEMA_VERSION)
                push!(sxml.network, StationXML.Network(code="AN"))
                push!(sxml.network[1].comment, StationXML.Comment("A comment"))
                io = IOBuffer()
                write(io, sxml)
                seekstart(io)
                sxml′ = StationXML.read(io)
                @test sxml == sxml′
                mktemp() do tempfile, f
                    write(f, sxml)
                    seekstart(f)
                    sxml″ = StationXML.read(f)
                    @test sxml == sxml″
                end
            end
        end

        @testset "Round trip file $file" for file in filenames
            sxml = gzipped_read(file)
            # Skip test files which are not expected to be written losslessly
            if VersionNumber(sxml.schema_version) < VersionNumber(StationXML.DEFAULT_SCHEMA_VERSION)
                continue
            end
            io = IOBuffer()
            write(io, sxml)
            seekstart(io)
            sxml′ = StationXML.read(io)
            @test sxml == sxml′
        end

        @testset "Warn removed fields" begin
            let sxml = gzipped_read("orfeus_NL_HGN.xml.gz")
                deleteat!(sxml.network[1].station[1].channel, 2:length(sxml.network[1].station[1].channel))
                @test_logs (:warn,
                    "Not writing field storage_format: removed in StationXML v$(StationXML.DEFAULT_SCHEMA_VERSION)"
                    ) write(devnull, sxml, warn=true)
                @test_logs write(devnull, sxml)
            end
        end
    end
end
