using StationXML, Test
import EzXML
using EzXML: ElementNode

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
            @test f("FrequencyDBVariation") == :frequency_db_variation
            @test f("URI") == :uri
            @test f("sourceID") == :source_id
            @test f("measurementMethod") == :measurement_method
            @test f("end") == :end_
            @test f("maximumTimeTear") == :maximum_time_tear
        end
        let f = StationXML.xml_element_name
            @test f(:module_name) == "Module"
            @test f(:module_uri) == "ModuleURI"
            @test f(:email) == "Email"
            @test f(:selected_number_channels) == "SelectedNumberChannels"
            @test f(:fir) == "FIR"
            @test f(:input_units) == "InputUnits"
            @test f(:frequency_db_variation) == "FrequencyDBVariation"
            @test f(:uri) == "URI"
        end
        let f = StationXML.xml_attribute_name
            @test f(:resource_id) == "resourceId"
            @test f(:i) == "i"
            @test f(:start_date) == "startDate"
            @test f(:code) == "code"
            @test f(:restricted_status) == "restrictedStatus"
            @test f(:number) == "number"
            @test f(:source_id) == "sourceID"
            @test f(:measurement_method) == "measurementMethod"
            @test f(:start) == "start"
            @test f(:end_) == "end"
            @test f(:maximum_time_tear) == "maximumTimeTear"
            @test_throws ArgumentError f(:made_up_attribute)
        end
        # Round-trip all names in the spec
        @testset "Specification v$(version)" for version in ("1.0", "1.1")
            let file = joinpath(@__DIR__, "data", "fdsn-station-$(version).xsd.xml"),
                    xml = EzXML.root(EzXML.readxml(file))
                # Elements
                for node in EzXML.findall("//xs:element", xml,
                        ["xs"=>"http://www.w3.org/2001/XMLSchema",
                        "fsx"=>"http://www.fdsn.org/xml/station/1"])
                    for att in EzXML.eachattribute(node)
                        if att.name == "name" && att.content != "FDSNStationXML"
                            @test StationXML.xml_element_name(StationXML.transform_name(att.content)) == att.content
                        end
                    end
                end
                # Attributes
                for node in EzXML.findall("//xs:attribute", xml,
                        ["xs"=>"http://www.w3.org/2001/XMLSchema",
                        "fsx"=>"http://www.fdsn.org/xml/station/1"])
                    for att in EzXML.eachattribute(node)
                        if att.name == "name"
                            @test StationXML.xml_attribute_name(StationXML.transform_name(att.content)) == att.content
                        end
                    end
                end
            end
        end
    end

    @testset "Enumeration macro" begin
        @eval StationXML.@enumerated_struct(ExampleStruct, ("A", "B", "D"))
        # FIXME: Work out correct escaping so permitted_values is evaluated
        #        in the correct scope (i.e., always StationXML)
        @test Main.permitted_values(ExampleStruct) == ("A", "B", "D")
        @test_throws LoadError @eval StationXML.@enumerated_struct(ExampleStruct2, ())
        @test_throws LoadError @eval StationXML.@enumerated_struct(ExampleStruct3, 1.0)
        @test isdefined(Main, :ExampleStruct)
        @test ExampleStruct("A") == ExampleStruct(value="A") isa ExampleStruct
        @test_throws ArgumentError ExampleStruct("C")
        @test convert(String, ExampleStruct("A")) == "A"
        @test convert(SubString{String}, ExampleStruct("B")) == SubString{String}("B")
        @test convert(ExampleStruct, "A") == ExampleStruct("A")
        @test convert(ExampleStruct, SubString{String}("B")) == ExampleStruct("B")
        @test parse(ExampleStruct, "A") == ExampleStruct("A")
        @test StationXML.local_parse(ExampleStruct, "B") == ExampleStruct("B")
        node = ElementNode("nodeName")
        node.content = "B"
        @test StationXML.parse_node(ExampleStruct, node, true) == ExampleStruct("B")
        @test StationXML.attribute_fields(ExampleStruct) == ()
        @test StationXML.element_fields(ExampleStruct) == ()
        @test StationXML.has_text_field(ExampleStruct) == true
        @test StationXML.text_field(ExampleStruct) == :value
    end
end
