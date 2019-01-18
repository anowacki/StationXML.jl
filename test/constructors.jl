using StationXML, Test

@testset "Constructors" begin
    @test_throws ArgumentError StationXML.Nominal("WEIRD_VALUE")
    @test_throws ArgumentError StationXML.Email("not_an_email_address")
    @test_throws ArgumentError StationXML.PhoneNumber(area_code=1,
        phone_number="not a phone number")
    @test_throws ArgumentError StationXML.RestrictedStatus("WEIRD_VALUE")
end
