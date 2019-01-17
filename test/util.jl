using StationXML, Test

@testset "Utils" begin
    @testset "XML escaping" begin
        let s = "a&amp;b&lt;c&gt;d&quot;e&apos;f", s′ = "a&b<c>d\"e'f"
            @test StationXML.xml_unescape(s) == s′
            @test StationXML.xml_escape(s′) == s
        end
    end

    @testset "Name transform" begin
        let f = StationXML.transform_name
            @test f("Module") == :module_name
            @test f("ModuleURI") == :module_uri
            @test f("Email") == :email
            @test f("SelectedNumberChannels") == :selected_number_channels
        end
    end
end
