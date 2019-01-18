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
    s = string(s)
    # Remove 'Group'
    s = replace(s, r"Group$"=>"")
    # CamelCase to Camel_Case
    s = replace(s, r"([a-z])([A-Z])"=>s"\1_\2")
    # lowercase
    s = lowercase(s)
    # Special cases
    s = replace(s, r"^module$"=>"module_name")
    Symbol(s)
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
