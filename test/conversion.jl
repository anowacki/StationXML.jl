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
            val = rand(StationXML.permitted_values(T))
            @test convert(T, val).value == val
            @test convert(String, T(val)) == val
        end
    end
end
