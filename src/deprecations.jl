# Deprecated fields and types

"""
    removed_fields(::Type) -> fields

Return all the `fields` removed in StationXML v1.1 for `Type` as a tuple
of `Symbol`s.

The default fallback method returns an empty tuple
"""
removed_fields(::Type) = ()

"""
    has_removed_fields(::Type) -> ::Bool

Return `true` if a type has fields which have been removed, and `false` otherwise.
"""
has_removed_fields(::Type{T}) where T = !isempty(removed_fields(T))
