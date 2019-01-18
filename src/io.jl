# Reading and parsing functions

"Flag for verbose debugging output in some functions."
const VERBOSE = Ref(false)

"""
    set_verbose!(true_or_false)

Set whether (`true`) or not (`false`) to print debugging information for the
`StationXML` module.
"""
set_verbose!(true_or_false) = VERBOSE[] = true_or_false

"""
    read(filename) -> ::FDSNStationXML

Read a FDSN StationXML file with name `filename` from disk and return a
`FDSNStationXML` object.
"""
read(filename) = readstring(String(Base.read(filename)), filename=filename)

"""
    readstring(xml_string) -> ::FDSNStationXML

Read the FDSN StationXML contained in `xml_string` and return a `FDSNStationXML` object.
"""
function readstring(xml_string; filename=nothing)
    xml = EzXML.parsexml(xml_string)
    file_string = filename === nothing ? "" : " in file $filename"
    xml_is_station_xml(xml) ||
        throw(ArgumentError("XML$file_string does not appear to be a StationXML file"))
    schema_version_is_okay(xml) ||
        throw(ArgumentError("StationXML$file_string does not have the correct schema version"))
    parse_node(xml.root)
end

"""
    xml_is_station_xml(xml)

Return `true` if `xml` appears to be a StationXML file.
"""
xml_is_station_xml(xml) = EzXML.hasroot(xml) && xml.root.name == "FDSNStationXML"

"""
    schema_version_is_okay(xml::EzXML.Document) -> ::Bool

Return `true` if this XML document is of the correct version.

Currently supported is only v1.0 of the FDSN specification.
"""
schema_version_is_okay(xml::EzXML.Document) = xml.root["schemaVersion"] == "1.0"

attributes_and_elements(node::EzXML.Node) = vcat(EzXML.attributes(node), EzXML.elements(node))

"""
    parse_node(root::EzXML.Node) -> ::FDSNStationXML

Parse the `root` node of a StationXML document.  This can be accessed as
`EzXML.readxml(file).root`.
"""
parse_node(root::EzXML.Node) = parse_node(FDSNStationXML, root)

"Types which can be directly parsed from a Node"
const ParsableTypes = Union{Type{String},Type{Float64},Type{Int}}
parse_node(T::ParsableTypes, node::EzXML.Node) = local_parse(T, node.content)
parse_node(T::Type{DateTime}, node::EzXML.Node) = DateTime(node.content)

"Enumeration types, which here have only a field `value::String`"
const StringEnumTypes = Union{Type{RestrictedStatus},Type{Nominal}}
parse_node(T::StringEnumTypes, node::EzXML.Node) = T(node.content)

"Types with a value field and attributes"
const ValueFieldType = Union{Type{NumeratorCoefficient},Type{Coefficient}}
parse_node(T::ValueFieldType, node::EzXML.Node) = parse_node(T, node, value=node.content)

"""
    parse_node(T, node::EzXML.Node; value=nothing) -> ::T

Create a type `T` from the StationXML module from an XML `node`.

If `value` is not `nothing`, then this node represents one of $ValueFieldType.
"""
function parse_node(T, node::EzXML.Node; value=nothing)
    VERBOSE[] && println("\n===\nParsing node type $T\n===")
    # Value field types have extra attributes
    is_value_field = Type{T} <: ValueFieldType
    VERBOSE[] && println("$T is a value field: $is_value_field")
    # Arguments to the keyword constructor of the type T
    args = Dict{Symbol,Any}()
    all_elements = attributes_and_elements(node)
    all_names = transform_name.([e.name for e in all_elements])
    VERBOSE[] && println("Element names: $all_names")
    VERBOSE[] && println("Field names: $(fieldnames(T))")
    # Fill in the field
    for field in fieldnames(T)
        field_type = fieldtype(T, field)
        VERBOSE[] && @show field, T, field_type
        # Skip fields not in our types
        field in all_names ||
            # Types with a `value` field with the same name as the upper field would
            # fail the test without `field == :value`
            (is_value_field && field == :value) ||
            continue
        if !(is_value_field && field == :value)
            elm = all_elements[findfirst(isequal(field), all_names)]
        end
        # Unions are Missing-supporting fields; should only every have two types
        if field_type isa Union
            VERBOSE[] && println("Field $field is a Union type")
            union_types = Base.uniontypes(field_type)
            @assert length(union_types) == 2 && Missing in union_types
            field_type = union_types[1] == Missing ? union_types[2] : union_types[1]
            VERBOSE[] && println("Field type is $field_type")
            args[field] = parse_node(field_type, elm)
            VERBOSE[] && println("\n   Saving $field as $(args[field])")
        # Multiple elements allowed
        elseif field_type <: AbstractVector
            el_type = eltype(field_type)
            VERBOSE[] && println("Element type is $el_type")
            ifields = findall(isequal(field), all_names)
            values = el_type[]
            for i in ifields
                push!(values, parse_node(el_type, all_elements[i]))
            end
            args[field] = values
            VERBOSE[] && println("\n   Saving $field as $values")
        # The value field of a ValueFieldType
        elseif field == :value && is_value_field
            @assert value !== nothing
            VERBOSE[] && println("Value of field is $(repr(value))")
            args[field] = local_parse(field_type, value)
            VERBOSE[] && println("\n   Saving $field as $(repr(args[field]))")
        # Just one (maybe optional) field
        else
            args[field] = parse_node(field_type, elm)
            VERBOSE[] && println("\n   Saving $field as $(repr(args[field]))")
        end
    end
    T(; args...)
end

# Version of parse which accepts String as the type.
# Don't define this for Base as this is type piracy.
local_tryparse(T::DataType, s::AbstractString) where S = T <: AbstractString ? s : tryparse(T, s)
local_parse(T::DataType, s::AbstractString) where S = T <: AbstractString ? s : parse(T, s)
