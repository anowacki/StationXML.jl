struct Network

end

"""
Top-level type for Station XML. Required field are Source (network ID
of the institution sending the message) and one or more Network containers or one or
more Station containers.
"""
@with_kw struct FDSNStationXML
    source::String
    sender::M{String} = missing
    "This differs from the schema because `module` is reserved in Julia"
    module_name::M{String} = missing
    module_uri::M{String} = missing
    created::DateTime
    networks::Vector{Network} = Network[]
    FDSNStationXML(source, sender, module_name, module_uri, created, networks) =
        new(source, sender, module_name, xml_unescape(module_uri), created, networks)
end
