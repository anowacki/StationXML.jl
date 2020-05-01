# Reading and parsing functions

"""
    read(filename; warn=false) -> ::FDSNStationXML

Read a FDSN StationXML file with name `filename` from disk and return a
`FDSNStationXML` object.

If `warn` is `true`, then print warnings when attributes and elements are
encountered in the StationXML which are not expected.

Note that StationXML.jl reads `filename` first before then parsing the
string read in.  Do not `read` StationXML files which are larger than your
system's memory.
"""
read(filename; warn=false) = readstring(String(Base.read(filename)), filename=filename, warn=warn)

"""
    readstring(xml_string; filename=nothing, warn=false) -> ::FDSNStationXML

Read the FDSN StationXML contained in `xml_string` and return a `FDSNStationXML` object.

Optionally specify the `filename` from which the string was read.

If `warn` is `true`, then print warnings when attributes and elements are
encountered in the StationXML which are not expected.
"""
function readstring(xml_string; filename=nothing, warn=false)
    xml = EzXML.parsexml(xml_string)
    file_string = filename === nothing ? "" : " in file $filename"
    xml_is_station_xml(xml) ||
        throw(ArgumentError("\"$file_string\" does not appear to be a StationXML file"))
    schema_version_is_okay(xml) ||
        throw(ArgumentError("StationXML$file_string does not have the correct schema version"))
    parse_node(xml.root, warn)
end

"""
    xml_is_station_xml(xml)

Return `true` if `xml` appears to be a StationXML file.
"""
xml_is_station_xml(xml) = EzXML.hasroot(xml) && xml.root.name == "FDSNStationXML"

"""
    schema_version_is_okay(xml::EzXML.Document) -> ::Bool

Return `true` if this XML document is of the correct version.

Currently fully supported is only v1.0 of the FDSN specification.
StationXML will parse v1.1 files, but ignore the additional information
provided in the new version.
"""
function schema_version_is_okay(xml::EzXML.Document)
    version = VersionNumber(xml.root["schemaVersion"])
    if version == v"1.0.0"
        return true
    elseif v"1.1.0" <= version < v"2"
        @warn("document is StationXML version $version; only v1.0 data will be read")
        return true
    else
        return false
    end
end

"""
    parse_node(root::EzXML.Node, warn=false) -> ::FDSNStationXML

Parse the `root` node of a StationXML document.  This can be accessed as
`EzXML.readxml(file).root`.

If `warn` is `true`, then warn about unexpected items in the StationXML.
"""
parse_node(root::EzXML.Node, warn::Bool=false) = parse_node(FDSNStationXML, root, warn)

"Types which can be directly parsed from a Node"
const ParsableTypes = Union{String, Float64, Int}

function parse_node(::Type{T}, node::EzXML.Node, warn::Bool=false) where {T<:ParsableTypes}
    @debug("Parsing $T from \"$(node.content)\"")
    local_parse(T, node.content)
end

# Handle dates with greater than millisecond precision by truncating to nearest millisecond,
# cope with UTC time zone information (ends with 'Z'), and convert non-UTC time zones to UTC
function parse_node(T::Type{DateTime}, node::EzXML.Node, warn::Bool=false)
    @debug("Parsing a DateTime from \"$(node.content)\"")
    # Remove sub-millisecond intervals
    m = match(r"(.*T..:..:..[\.]?)([0-9]{0,3})[0-9]*([-+Z].*)*", node.content)
    m === nothing && throw(ArgumentError("invalid date-time string \"$(node.content)\""))
    dt = DateTime(m.captures[1] * m.captures[2]) # Local date to ms
    (m.captures[3] === nothing || m.captures[3] in ("", "Z", "+00:00", "-00:00")) && return dt # UTC
    pm = m.captures[3][1] # Whether ahead or behind UTC
    offset = Time(m.captures[3][2:end]) - Time("00:00")
    dt = pm == '+' ? dt + offset : dt - offset
    dt
end

"""
    parse_node(::Type{Union{Missing,T}}, node::EzXML.Node, warn=false) where T -> ::T

Parse an XML node into a union of a type `T` with `Missing`, for optional
fields.
"""
function parse_node(::Type{Union{Missing,T}}, node::EzXML.Node, warn::Bool=false) where T
    @debug("Parsing a Union{Missing,$T} from \"$(node.content)\"")
    parse_node(T, node, warn)
end

"""
    parse_node(::Type{T}, node::EzXML.Node, warn::Bool=false) where T -> ::T

Parse the contents of `node` and return a type `T` containing the
information 
"""
function parse_node(T, node::EzXML.Node, warn::Bool=false)
    @debug("Parsing $T from fallback method")
    attributes = attribute_fields(T)
    @debug("  $T has attributes $attributes")
    args = Dict{Symbol,Any}()
    # Attributes
    for att in EzXML.eachattribute(node)
        field = transform_name(att.name)
        @debug("  Parsing attribute $field")
        if field in attributes
            fieldT = fieldtype(T, field)
            @debug("    Parsing $field as a $fieldT")
            args[field] = local_parse(fieldT, att.content)
        else
            warn && @warn("unexpected attribute \"$(att.name)\" (:$field) for $T")
        end
    end
    # Elements
    elements = element_fields(T)
    @debug("  $T has elements $(collect(elements))")
    for elm in EzXML.eachelement(node)
        field = transform_name(elm.name)
        @debug("  Parsing element $field")
        if field in elements
            fieldT = fieldtype(T, field)
            @debug("    Parsing $field as a $fieldT")
            if fieldT <: AbstractVector
                # Create an empty vector of fieldTs the first time we hit this
                if !haskey(args, field)
                    args[field] = fieldT()
                    @debug("    Creating new array type $fieldT")
                end
                @debug("    Parsing vector element $(fieldT)")
                push!(args[field], parse_node(eltype(fieldT), elm, warn))
                @debug("    Vector of $(eltype(fieldT)) length: $(length(args[field]))")
            else
                args[field] = parse_node(fieldT, elm, warn)
                @debug("$fieldT $elm $warn")
                @debug("    Got value of $(args[field]) for $field")
            end
        else
            warn && @warn("unexpected element \"$(elm.name)\" for $T")
        end
    end
    @debug("Args for $T: $args")
    T(; args...)
end

# Version of parse which accepts String as the type.
# Don't define this for Base as this is type piracy.
local_tryparse(T::Type{<:AbstractString}, s::AbstractString) = s
local_tryparse(T::DataType, s::AbstractString) = tryparse(T, s)
local_parse(T::Type{<:AbstractString}, s::AbstractString) = s
local_parse(T::DataType, s::AbstractString) = parse(T, s)
local_parse(::Type{Union{Missing, T}}, s::AbstractString) where T = local_parse(T, s)
