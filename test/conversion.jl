# Conversion to and from Base types
using StationXML, Test
using InteractiveUtils: subtypes

@testset "Conversion" begin
    @testset "NumberType" begin
        @testset "$T" for T in subtypes(StationXML.NumberType)
            val = rand()
            @test convert(T, val).value == val
            @test convert(Float64, T(val)) == val
            @test convert(Complex{Float32}, T(val)) == Float32(val) + 0im
        end
    end

    @testset "EnumeratedStruct" begin
        @testset "$T" for T in subtypes(StationXML.EnumeratedStruct)
            val = first(StationXML.permitted_values(T))
            @test convert(T, val).value == val
            @test convert(String, T(val)) == val
        end
    end

    @testset "Identifier" begin
        let value = "some random text"
            @test convert(String, StationXML.Identifier(value)) == value
            @test convert(StationXML.Identifier, value).value == value
        end
    end

    @testset "Email" begin
        let address = "test.name@example.com"
            @test convert(String, StationXML.Email(address)) == address
            @test convert(StationXML.Email, address).value == address
            @test_throws ArgumentError convert(StationXML.Email, "not an email address")
        end
    end

    @testset "Comment" begin
        let comment = "Some text comment"
            @test convert(StationXML.Comment, comment).value == comment
        end
    end

    @testset "Units" begin
        let unit = "AMPERES"
            @test convert(StationXML.Units, unit).name == unit
            @test convert(String, StationXML.Units(unit)) == unit
        end
    end
end
