# Wrapper types and functions for XML interaction.

const Node = EzXML.Node

"""
    $(DocStringExtensions.SIGNATURES)

Get the root node of an XML document.
"""
xml_hasroot(xml) = EzXML.hasroot(xml)

"""
    $(DocStringExtensions.SIGNATURES)

Parse a string into an XML document.
"""
parse_xml(xmlstring) = EzXML.parsexml(xmlstring)