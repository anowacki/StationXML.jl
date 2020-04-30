using Test
using StationXML

@testset "Types" begin
    # Types with restrictions on what values they can take
    @testset "Restricted types" begin
        # Types with optional unit but which can take only one value
        @testset "Units" begin
            for (T, unit) in (
                    (StationXML.Second, "SECONDS"),
                    (StationXML.Voltage, "VOLTS"),
                    (StationXML.Angle, "DEGREES"),
                    (StationXML.Azimuth, "DEGREES"),
                    (StationXML.Dip, "DEGREES"),
                    (StationXML.ClockDrift, "SECONDS/SAMPLE"),
                    (StationXML.Frequency, "HERTZ"),
                    (StationXML.SampleRate, "SAMPLES/S"),
                    (StationXML.Latitude, "DEGREES"),
                    (StationXML.Longitude, "DEGREES"))
                obj = T(0)
                @test obj.unit === missing
                obj.unit = unit
                @test obj.unit == unit
                @test_throws ArgumentError obj.unit = "invalid unit string"
                @test_throws ArgumentError T(; value=0, unit="invalid unit string")
            end
        end

        # Types which can take only a range of values
        @testset "Value ranges" begin
            # Float- and FloatNoUnit-derived types
            for (T, vals) in (
                (StationXML.Angle, (-361, 361)),
                (StationXML.Azimuth, (-1, 361)),
                (StationXML.Dip, (-91, 91)),
                (StationXML.ClockDrift, (-1,)),
                (StationXML.Latitude, (-91, 91)),
                (StationXML.Longitude, (-361, 361)),
                    )
                for val in vals
                    @test_throws ArgumentError T(val)
                    t = T(0)
                    @test_throws ArgumentError t.value = val
                end
            end
            # Enumerated types
            @test_throws ArgumentError StationXML.Nominal("WEIRD_VALUE")
            @test_throws ArgumentError StationXML.Email("not_an_email_address")
            @test_throws ArgumentError StationXML.PhoneNumber(area_code=1,
                phone_number="not a phone number")
            @test_throws ArgumentError StationXML.RestrictedStatus("WEIRD_VALUE")
            # Network
            @test_throws ArgumentError StationXML.Network(code="AN", total_number_stations=-1)
            @test_throws ArgumentError StationXML.Network(code="AN", selected_number_stations=-1)
            @test_throws ArgumentError StationXML.Coefficient(value=1, number=-1)
        end
    end

    # Types which only permit certain combinations of fields to be set
    @testset "Field combinations" begin
        # All or none of the frequency_* fields for Sensitivity
        let input_units = StationXML.Units("M/S"), output_units = StationXML.Units("V")
            @test_throws ArgumentError StationXML.Sensitivity(value=1, frequency=0,
                input_units=input_units, output_units=output_units,
                frequency_start=1)
            @test_throws ArgumentError StationXML.Sensitivity(value=1, frequency=0,
                input_units=input_units, output_units=output_units,
                frequency_start=1, frequency_end=2)
            @test_throws ArgumentError StationXML.Sensitivity(value=1, frequency=0,
                input_units=input_units, output_units=output_units,
                frequency_end=1, frequency_db_variation=2)
        end
        # ResponseStage stage number and only one type of function
        let iu = StationXML.Units("M/S"), ou = StationXML.Units("V"),
                    pz = StationXML.PolesZeros(input_units=iu,
                                               output_units=ou,
                                               pz_transfer_function_type="LAPLACE (HERTZ)",
                                               normalization_frequency=1),
                coefs = StationXML.Coefficients(input_units=iu, output_units=ou,
                                                cf_transfer_function_type="ANALOG (HERTZ)"),
                resplist = StationXML.ResponseList(input_units=iu, output_units=ou),
                fir = StationXML.FIR(input_units=iu, output_units=ou, symmetry="NONE"),
                poly = StationXML.Polynomial(input_units=iu, output_units=ou,
                                             frequency_lower_bound=StationXML.Frequency(0),
                                             frequency_upper_bound=StationXML.Frequency(1),
                                             approximation_lower_bound=0,
                                             approximation_upper_bound=1,
                                             maximum_error=1)
            # Only one type allowed
            all_args = (:poles_zeros=>pz, :coefficients=>coefs,
                    :response_list=>resplist, :fir=>fir, :polynomial=>poly)
            for args in (all_args[1:2], all_args[1:3], all_args[1:4], all_args)
                @test_throws ArgumentError StationXML.ResponseStage(; number=1, args...)
            end
            for arg in all_args
                @test StationXML.ResponseStage(; (:number=>1, arg)...) isa StationXML.ResponseStage
            end
            # Stage number >= 1
            @test_throws ArgumentError StationXML.ResponseStage(poles_zeros=pz, number=-1)
        end
    end
end
