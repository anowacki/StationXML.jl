# Reading, writing and parsing functions
"""
    schema_version_is_okay(xml::EzXML.Document) -> ::Bool

Return `true` if this XML document is of the correct version.

Currently supported is only v1.0 of the FDSN specification.
"""
function schema_version_is_okay(xml::EzXML.Document)
    EzXML.hasroot(xml) ||
        throw(ArgumentError("XML document does not have a root node"))
    xml.root["schemaVersion"] == "1.0"
end
