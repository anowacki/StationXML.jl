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
    elseif s === :restricted_status
        return "restrictedStatus"
    elseif s === :alternate_code
        return "alternateCode"
    elseif s === :historical_code
        return "historicalCode"
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
    @enumerated_struct(name, values)

Create a `struct` called `name` with a single `String` field, `:value`, which
must match one of the items in `values`.

Also create a keyword constructor with one required keyword argument,
`value`, a conversion between the struct and an `AbstractString`,
and a `parse_node` method to convert a node into a `name`.

Define conversions between `String` and the struct.

# Example

The following code
```
@enumerated_struct(Example, ("A", "B", "D"))
```

is equivalent to
```
struct Example
    value::String
    function Example(value)
        if value ∉ ("A", "B", "D")
            throw(ArgumentError("value must be one of \"A\", \"B\" or \"D\""))
        end
        new(value)
    end
    Example(; value) = Example(value)
end

Base.convert(::Type{T}, e::Example) where {T<:AbstractString} = T(e.value)
Base.convert(::Type{Example}, s::AbstractString) = Example(s)

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
    name = esc(name)
    quote
        """
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
        struct $name
            value::String
            function $name(value)
                if value ∉ $values
                    $(esc(throw))($(esc(ArgumentError))("value must be one of $($values_string)"))
                end
                new(value)
            end
            $name(; value) = $name(value)
        end
        $(@__MODULE__).attribute_fields(::Type{$name}) = ()
        $(@__MODULE__).element_fields(::Type{$name}) = ()
        Base.convert(::Type{S}, s::$name) where {S<:AbstractString} = S(s.value)
        Base.convert(::Type{$name}, s::AbstractString) = $(name)(s)
        $(@__MODULE__).parse_node(::Type{$name}, node::EzXML.Node, warn::Bool=false) = $(name)(node.content)
        local_parse(::Type{$name}, s::AbstractString) = $(name)(s)
        Base.parse(::Type{$name}, s::AbstractString) = $(name)(s)
    end
end
