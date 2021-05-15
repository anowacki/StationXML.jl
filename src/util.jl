# Utility functions

"""
    transform_name(s::AbstractString) -> s′::Symbol

Transform the name of an attribute or element of an FDSN Station XML
document into a `Symbol` suitable for assignment into a `struct`.

For example:

```julia
julia> name = "EmailType";

julia> transform_name(name)
:email
```
"""
function transform_name(s)
    # Special cases
    if s == "FrequencyDBVariation"
        return :frequency_db_variation
    end
    s = string(s)
    # CamelCase to Camel_Case
    s = replace(s, r"([a-z])([A-Z])"=>s"\1_\2")
    # lowercase
    s = lowercase(s)
    # Special cases
    s = replace(s, r"^module$"=>"module_name")
    Symbol(s)
end

"""
    xml_element_name(s::Symbol) -> name

Transform a field name `s` of a struct into its equivalent FDSN StationXML
element name.

# Example
```julia
julia> StationXML.xml_element_name(:module_name)
"Module"
```
"""
function xml_element_name(s::Symbol)
    # Special cases
    if s === :module_name
        return "Module"
    elseif s === :module_uri
        return "ModuleURI"
    elseif s === :fir
        return "FIR"
    elseif s === :frequency_db_variation
        return "FrequencyDBVariation"
    elseif s === :uri
        return "URI"
    end
    name = String(s)
    name = replace(name, "_"=>" ")
    name = titlecase(name)
    name = replace(name, " "=>"")
end

"""
    xml_attribute_name(s::Symbol) -> name

Transform a field name `s` of a struct into its equivalent FDSN StationXML
attribute name.

# Example
```julia
julia> StationXML.xml_attribute_name(:schema_version)
"schemaVersion"
```
"""
function xml_attribute_name(s::Symbol)
    if s === :schema_version
        return "schemaVersion"
    elseif s === :unit
        return "unit"
    elseif s === :location_code
        return "locationCode"
    elseif s === :resource_id
        return "resourceId"
    elseif s === :number
        return "number"
    elseif s === :id
        return "id"
    elseif s === :i
        return "i"
    elseif s === :number
        return "number"
    elseif s === :plus_error
        return "plusError"
    elseif s === :minus_error
        return "minusError"
    elseif s === :measurement_method
        return "measurementMethod"
    elseif s === :datum
        return "datum"
    elseif s === :description
        return "description"
    elseif s === :name
        return "name"
    elseif s === :code
        return "code"
    elseif s === :start_date
        return "startDate"
    elseif s === :end_date
        return "endDate"
    elseif s === :source_id
        return "sourceID"
    elseif s === :restricted_status
        return "restrictedStatus"
    elseif s === :alternate_code
        return "alternateCode"
    elseif s === :historical_code
        return "historicalCode"
    elseif s === :subject
        return "subject"
    else
        throw(ArgumentError("$s is not a known StationXML attribute name"))
    end
end

"""
    xml_unescape(s) -> s′

Replace escaped occurrences of the five XML character entity
references &, <, >, " and ' with their unescaped equivalents.

Reference:
    https://en.wikipedia.org/wiki/Character_encodings_in_HTML#XML_character_references
"""
xml_unescape(s) =
    # Workaround for JuliaLang/julia#28967
                  reduce(replace,
                         ("&amp;"  => "&",
                          "&lt;"   => "<",
                          "&gt;"   => ">",
                          "&quot;" => "\"",
                          "&apos;" => "'"),
                         init=s)

"""
    xml_escape(s) -> s′

Replace unescaped occurrences of the five XML characters
&, <, >, " and ' with their escaped equivalents.

Reference:
    https://en.wikipedia.org/wiki/Character_encodings_in_HTML#XML_character_references
"""
xml_escape(s) =
    # Workaround for JuliaLang/julia#28967
                reduce(replace,
                       ("&"  => "&amp;",
                        "<"  => "&lt;",
                        ">"  => "&gt;",
                        "\"" => "&quot;",
                        "'"  => "&apos;"),
                       init=s)

"""
    xs_nmtoken_or_throw(s) -> token

Return `token`, which is guaranteed to conform to the `xsd:NMTOKEN` specification
of an XML token.  If `s` cannot be made into a valid token, then an
`ArgumentError` is thrown.

From the XML Schema 1.0 specification:
> The type `xsd:NMTOKEN` represents a single string token. `xsd:NMTOKEN`
> values may consist of letters, digits, periods (`.`), hyphens (`-`),
> underscores (`_`), and colons (`:`). They may start with any of these
> characters. `xsd:NMTOKEN` has a `whiteSpace` facet value of `collapse`,
> so any leading or trailing whitespace will be removed. However, no
> whitespace may appear within the value itself.

!!! note
    This implementation forbids non-ASCII characters, though the specification
    [may tolerate them](http://books.xmlschemata.org/relaxng/ch19-77231.html).
"""
function xs_nmtoken_or_throw(s)
    s = strip(s)
    occursin(r"^[a-zA-Z0-9._\-:]*$", s) ||
        throw(ArgumentError("string \"$s\" is not a valid token"))
    s
end

"""
    abstract type EnumeratedStruct end

Supertype of all structs made with the [`@enumerated_struct`](@ref) macro.
"""
abstract type EnumeratedStruct end

"""
    @enumerated_struct(name, values)

Create a `struct` called `name` with a single `String` field, `:value`, which
must match one of the items in `values`.

Create a keyword constructor with one required keyword argument,
`value`, and add a method for `permitted_values` returning the values
which can be used in `name`.

The struct is a subtype of [`StationXML.EnumeratedStruct`](@ref),
and hence has methods defined for the following functions:

- [`StationXML.attribute_fields`](@ref)
- [`StationXML.element_fields`](@ref)
- [`StationXML.has_text_field`](@ref)
- [`StationXML.text_field`](@ref)
- [`StationXML.parse_node`](@ref)
- [`StationXML.local_parse`](@ref)

See [`StationXML.EnumeratedStruct`](@ref) for more details on other
methods defined for the new type.

# Example

The following code
```
@enumerated_struct(Example, ("A", "B", "D"))
```

is equivalent to
```
struct Example <: StationXML.EnumeratedStruct
    value::String
    function Example(value)
        if value ∉ ("A", "B", "D")
            throw(ArgumentError("value must be one of \"A\", \"B\" or \"D\""))
        end
        new(value)
    end
    Example(; value) = Example(value)
end

# WARNING!
# This method is added to the module from which the macro is called,
# not StationXML!
permitted_values(::Type{Example}) = (\"A\", \"B\", \"D\")
```
"""
macro enumerated_struct(name, values)
    hasfield(typeof(values), :head) && values.head === :tuple ||
        throw(ArgumentError("final argument must be a tuple of values"))
    values_string = string(values)
    # A nice set of Markdown-formatted values.
    values_docstring = join((string("`\"", val, "\"`") for val in values.args), ", ", " or ")
    # For the example in the docstring
    n_values = length(values.args)
    n_values == 0 && throw(ArgumentError("number of permitted values cannot be 0"))
    first_value = string(first(values.args))
    second_value = n_values == 1 ? first_value : string(values.args[2])
    module_name = :($(@__MODULE__).$name)
    name = esc(name)
    quote
        """
            $($name) <: EnumeratedStruct

        # Constructors

            $($name)(value)
            $($name)(; value)

        Enumerated struct containing a single string which must be one
        of the following: $($values_docstring).

        This field is named `value`.

        Note that when a field of another type is a `$($name)`, it
        is not necessary to assign a field of type `$($name)` to the
        field.  Instead, one can simply use a `String`, from which a
        `$($name)` will be automatically constructed.

        For this reason, `$($name)` is not exported even when bringing
        StationXML's types into scope by doing `using StationXML.Types`.

        # Example
        ```
        julia> using StationXML

        julia> mutable struct ExampleStruct
                   field::$($name)
               end

        julia> es = ExampleStruct("$($first_value)")
        ExampleStruct($($name)("$($first_value)"))

        julia> es.field = "$($second_value)"
        "$($second_value)"
        ```
        """
        struct $name <: $(esc(EnumeratedStruct))
            value::String
            function $name(value)
                if value ∉ $values
                    $(esc(throw))($(esc(ArgumentError))("value must be one of $($values_string)"))
                end
                new(value)
            end
            $name(; value) = $name(value)
        end

        # FIXME: Work out correct escaping so permitted_values is always
        #        added to the StationXML module and not the module in which
        #        the macro is called.
        #        In other words, this currently adds a method to the
        #        module where we call @enumerated_struct, though this
        #        is fine if it's only used in this module.
        $(esc(:(permitted_values)))(::$(esc(Type)){$name}) = $values
    end
end

attribute_fields(::Type{<:EnumeratedStruct}) = ()
element_fields(::Type{<:EnumeratedStruct}) = ()
has_text_field(::Type{<:EnumeratedStruct}) = true
text_field(::Type{<:EnumeratedStruct}) = :value
Base.convert(::Type{S}, s::EnumeratedStruct) where {S<:AbstractString} = S(s.value)
Base.convert(::Type{T}, s::AbstractString) where {T<:EnumeratedStruct} = T(s)
parse_node(::Type{T}, node::EzXML.Node, warn::Bool=false) where {T<:EnumeratedStruct} = T(node.content)
local_parse(::Type{T}, s::AbstractString) where {T<:EnumeratedStruct} = T(s)
Base.parse(::Type{T}, s::AbstractString) where {T<:EnumeratedStruct} = T(s)
