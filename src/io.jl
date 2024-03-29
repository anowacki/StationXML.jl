# Reading and parsing functions

#
# Reading
#

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
function read(filename; warn=false)
    xml = EzXML.readxml(filename)
    _check_and_parse_xml(xml, filename, warn)
end

"""
    readstring(xml_string; filename=nothing, warn=false) -> ::FDSNStationXML

Read the FDSN StationXML contained in `xml_string` and return a `FDSNStationXML` object.

Optionally specify the `filename` from which the string was read.

If `warn` is `true`, then print warnings when attributes and elements are
encountered in the StationXML which are not expected.
"""
function readstring(xml_string; filename=nothing, warn=false)
    xml = EzXML.parsexml(xml_string)
    _check_and_parse_xml(xml, filename, warn)
end

function _check_and_parse_xml(xml, filename, warn)
    file_string = (filename === nothing || filename isa IO) ? "" : " in file $filename"
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
    if version < v"1.2"
        return true
    elseif v"1.2.0" <= version < v"2"
        @warn("document is StationXML version $version; only v1.1 data will be read")
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
const ParsableTypes = Union{String, Float64, Int, DateTime}

function parse_node(::Type{T}, node::EzXML.Node, warn::Bool=false) where {T<:ParsableTypes}
    @debug("Parsing $T from \"$(node.content)\"")
    local_parse(T, node.content)
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
information held within it.
"""
parse_node

@generated function parse_node(::Type{T}, node::EzXML.Node, warn::Bool=false) where T
    # Lists of fields
    attributes = attribute_fields(T)
    elements = collect(element_fields(T))
    fields = fieldnames(T)
    field_types = fieldtype.(Ref(T), fields)
    attribute_names = xml_attribute_name.(attributes)
    attribute_types = fieldtype.(Ref(T), attributes)
    element_names = xml_element_name.(elements)
    element_types = fieldtype.(Ref(T), elements)

    quote
        # Define function-local variables to pass in to constructor
        $([typ <: AbstractArray ?
            :($f = $(typ)()) :
            typ isa Union ?
                :(local $f = missing) :
                :(local $f)
            for (f, typ) in zip(fields, field_types)]...)

        # Attributes (always scalars)
        for att in EzXML.eachattribute(node)
            $([:(
                if att.name === $att_name
                    $var_name = local_parse($ftype, att.content)
                    continue
                end
                ) for (att_name, var_name, ftype) in
                    zip(attribute_names, attributes, attribute_types)]...)
        end

        # Elements
        for elm in EzXML.eachelement(node)
            # Scalars
            $([:(
                if elm.name === $elm_name
                    $var_name = parse_node($ftype, elm, warn)
                    continue
                end
                ) for (elm_name, var_name, ftype) in
                    zip(element_names, elements, element_types)
                    if !(ftype <: AbstractArray)]...)
            # Vectors
            $([:(
                if elm.name === $elm_name
                    push!($var_name, parse_node($(eltype(ftype)), elm, warn))
                    continue
                end
                ) for (elm_name, var_name, ftype) in
                    zip(element_names, elements, element_types)
                    if ftype <: AbstractArray]...)
        end

        # Pass variables to inner constructor
        $(T)($([:($f) for f in fields]...))
    end
end

# Version of parse which accepts String as the type.
# Don't define this for Base as this is type piracy.
local_tryparse(::Type{T}, s::AbstractString) where T<:AbstractString = s
local_tryparse(::Type{T}, s::AbstractString) where T = tryparse(T, s)
local_parse(::Type{<:AbstractString}, s::AbstractString) = s
local_parse(::Type{T}, s::AbstractString) where T = parse(T, s)
local_parse(::Type{Union{Missing, T}}, s::AbstractString) where T = local_parse(T, s)

# Handle dates with greater than millisecond precision by truncating to nearest millisecond,
# cope with UTC time zone information (ends with 'Z'), and convert non-UTC time zones to UTC
function local_parse(::Type{DateTime}, s::AbstractString)
    # Remove sub-millisecond intervals
    m = match(r"(.*T..:..:..[\.]?)([0-9]{0,3})[0-9]*([-+Z].*)*", s)
    m === nothing && throw(ArgumentError("invalid date-time string \"$(s)\""))
    dt = DateTime(m.captures[1] * m.captures[2]) # Local date to ms
    (m.captures[3] === nothing || m.captures[3] in ("", "Z", "+00:00", "-00:00")) && return dt # UTC
    pm = m.captures[3][1] # Whether ahead or behind UTC
    offset = Time(m.captures[3][2:end]) - Time("00:00")
    dt = pm == '+' ? dt + offset : dt - offset
    dt
end

#
# Writing
#

"""
    write(io, sxml::FDSNStationXML)

Write a `FDSNStationXML` structure to `io`, which may be a filename
or a `Base.IO` type.

# Example
(Note that `"example_stationxml_file.xml"` may not exist.)
```
julia> sxml = StationXML.read("example_stationxml_file.xml");

julia> write("new_file.xml", sxml)
```
"""
Base.write(io::IO, sxml::FDSNStationXML; warn=false) = EzXML.prettyprint(io, xmldoc(sxml; warn=warn))


"""
    xmldoc(sxml::FDSNStationXML; warn=false) -> xml::EzXML.XMLDocument

Create an XML document from `sxml`, a set of events of type `EventParameters`.
`xml` is an `EzXML.XMLDocument` suitable for output.

The StationXML document `xml` may be written with `write(io, xml)`
or converted to a string with `string(xml)`.

If `warn` is `true`, then warn about the presence of fields which have been
removed from the most recent StationXML specification, and hence will not be written.
"""
function xmldoc(sxml::FDSNStationXML; warn=false)
    version = "1"
    doc = EzXML.XMLDocument("1.0")
    root = EzXML.ElementNode("FDSNStationXML")
    # FIXME: Is this the only way to set a namespace in EzXML?
    namespace = EzXML.AttributeNode("xmlns", "http://www.fdsn.org/xml/station/" * version)
    EzXML.link!(root, namespace)
    EzXML.setroot!(doc, root)
    add_attributes!(root, sxml, warn)
    add_elements!(root, :fdsn_station_xml, sxml, warn)
    doc
end

"""
    add_attributes!(node, value, warn) -> node

Add the attribute fields from the structure `value` to a `node`.

If `warn` is `true`, then  warn about the presence of attributes which have
been removed from the most recent StationXML specification, and hence will not be added.
"""
function add_attributes!(node, value::T, warn) where T
    for field in attribute_fields(T)
        # Skip fields read from v1.0 but removed from v1.1
        if has_removed_fields(T) && field in removed_fields(T)
            warn && _warn_removed_field(field)
            continue
        # Write out StationXML v1.1 regardless of what was read in
        elseif field === :schema_version
            add_attribute!(node, field, DEFAULT_SCHEMA_VERSION)
            continue
        end
        content = getfield(value, field)
        content === missing && continue
        add_attribute!(node, field, content)
    end
    node
end

function add_attribute!(node, field, value)
    value === missing && return node
    name = xml_attribute_name(field)
    attr = EzXML.AttributeNode(name, string(value))
    EzXML.link!(node, attr)
    node
end

add_attribute!(node, field, value::EnumeratedStruct) = add_attribute!(node, field, value.value)

"""
    add_elements!(node, parent_field, value, warn) -> node

Add the elements to `node` contained within `value`.  `parent_field`
is the name of the field which contains `value`.  If `warn` is `true`, then
warn about the presence of elements which have been removed from the
most recent StationXML specification, and hence will not be added.
"""
function add_elements!(node, parent_field, value::T, warn) where T
    for field in element_fields(T)
        @debug("adding $parent_field: $field")
        # Skip fields read from v1.0 but removed from v1.1
        if has_removed_fields(T) && field in removed_fields(T)
            warn && _warn_removed_field(field)
            continue
        end
        content = getfield(value, field)
        if content === missing
            continue
        end
        add_element!(node, field, content, warn)
    end
    node
end

function add_elements!(node, parent_field, values::AbstractArray, warn)
    for value in values
        add_elements!(node, parent_field, value, warn)
    end
    node
end

"Union of types which can be natively written"
const WritableTypes = Union{Float64, Int, String, DateTime, Bool}

"""
    add_element!(node, field, value, warn) -> node

Add an element called `field` to `node` with content `value`.

`warn` is passed on to [`add_attributes!`](@ref) and [`add_elements!`](@ref).
"""
function add_element!(node, field, value::WritableTypes, warn)
    @debug("  adding writable type name \"$field\" with value \"$value\"")
    name = xml_element_name(field)
    elem = EzXML.ElementNode(name)
    add_text!(elem, value)
    EzXML.link!(node, elem)
    node
end

function add_element!(node, field, value::EnumeratedStruct, warn)
    @debug("  adding enumerated struct name \"$field\" with value \"$value\"")
    add_element!(node, field, value.value, warn)
end

function add_element!(node, field, values::AbstractArray, warn)
    @debug("  adding array type name \"$field\" with $(length(values)) values")
    for value in values
        add_element!(node, field, value, warn)
    end
    node
end

# Fallback for structs
function add_element!(node, field, value::T, warn) where T
    @debug("  adding compound type name \"$field\" of type \"$(typeof(value))\"")
    name = xml_element_name(field)
    elem = EzXML.ElementNode(name)
    EzXML.link!(node, elem)
    add_attributes!(elem, value, warn)
    add_elements!(elem, field, value, warn)
    if has_text_field(T)
        value_field = text_field(T)
        add_text!(elem, getfield(value, value_field))
    end
    node
end

"Add simple text to an element node"
function add_text!(node, value::WritableTypes)
    @debug("  adding simple text with value \"$value\"")
    content = EzXML.TextNode(string(value))
    EzXML.link!(node, content)
    node
end

"""
Issue a warning about an attribute or element `field` which is no longer
present in the most recent StationXML standard and hence will not be written.
"""
_warn_removed_field(field) =
    @warn("Not writing field $field: removed in StationXML v$DEFAULT_SCHEMA_VERSION")
