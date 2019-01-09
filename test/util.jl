using StationXML, Test

@testset "Utils" begin
    @testset "XML escaping" begin
        let s = "a&amp;b&lt;c&gt;d&quot;e&apos;f", s′ = "a&b<c>d\"e'f"
            @test StationXML.xml_unescape(s) == s′
            @test StationXML.xml_escape(s′) == s
        end
    end
end
