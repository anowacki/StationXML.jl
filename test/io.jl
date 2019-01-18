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
            # Channel
            bhe = channels(sxml)[1]
            @test bhe.latitude ≈ 49.187801
            @test bhe.longitude ≈ -2.171698
            @test bhe.elevation ≈ 39.0
            @test bhe.depth ≈ 0.0 atol=1e-5
            @test bhe.azimuth ≈ 90.0
            @test bhe.dip ≈ 0.0 atol=1e-5
            @test bhe.clock_drift ≈ 0.0 atol=1e-5
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
            @test pz.pz_transfer_function_type == "LAPLACE (RADIANS/SECOND)"
            @test pz.normalization_factor ≈ 2.31323e9
            @test pz.normalization_frequency ≈ 1.0
            @test length(pz.zero) == 4
            @test length(pz.pole) == 7
            @test [p.real for p in pz.pole] ≈ [-0.01815, -0.01815, -196.0, -196.0, -732.0, -732.0, -173.0]
            @test [p.imaginary for p in pz.pole] ≈ [0.01799, -0.01799, 231.0, -231.0, 1415.0, -1415.0, 0.0]
            cf = bhe.response.stage[2].coefficients
            @test !ismissing(cf)
            @test cf.input_units.name == pz.output_units.name == "V"
            @test cf.output_units.name == "COUNTS"
            @test cf.cf_transfer_function_type == "DIGITAL"
            @test length(cf.numerator) == length(cf.denominator) == 0
            dec = bhe.response.stage[2].decimation
            @test !ismissing(dec)
            @test dec.input_sample_rate ≈ 30_000.0
            @test dec.factor ≈ 1.0
            @test dec.offset ≈ 0.0 atol=1e-5
            @test dec.delay ≈ 0.0 atol=1e-5
            @test dec.correction ≈ 0.0 atol=1e-5
            @test bhe.response.stage[2].stage_gain.value ≈ 400_000.0
            @test bhe.response.stage[2].stage_gain.frequency ≈ 0.0 atol=1e-5
        end
    end
end
