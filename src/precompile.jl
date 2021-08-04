# Precompilation statements

#=
    Reading and parsing
=#
precompile(parse_node, (EzXML.Node, Bool))

# Hacky way to get at all the types we create
for name in names(StationXML, all=true)
    name_str = String(name)
    if occursin(r"^[A-Z]", name_str) && !occursin(r"^BASE", name_str)
        name in (:M, :COMPARABLE_TYPES, :StationXML, :Numerator, :Denominator) && continue
        getfield(StationXML, name) isa DataType || continue
        @eval begin
            # Parsing
            precompile(parse_node, (Type{$name}, EzXML.Node, Bool))
            precompile(parse_node, (Type{Union{$name,Missing}}, EzXML.Node, Bool))
            # Construction
            precompile($name, ())
            # Equality
            precompile(==, ($name, $name))
            precompile(==, ($name, Missing))
            precompile(==, (Missing, $name))
            precompile(local_equals, ($name, $name))
            precompile(local_equals, ($name, Missing))
            precompile(local_equals, (Missing, $name))
        end
        # Others
        for func in (:attribute_fields, :element_fields, :has_text_field, :text_field,
                :removed_fields)
            @eval precompile($func, ($name,))
        end
    end
end

# Hacky way to get members of a Union
_union_types(x::Union) = (x.a, _union_types(x.b)...)
_union_types(x::Type) = (x,)

for T in _union_types(ParsableTypes)
    @eval begin
        precompile(parse_node, (Type{$T}, EzXML.Node, Bool))
        precompile(parse_node, (Type{Union{Missing,$T}}, EzXML.Node, Bool))
        precompile(local_parse, (Type{$T}, String))
        precompile(local_parse, (Type{Union{$T,Missing}}, String))
        precompile(local_tryparse, (Type{$T}, String))
        precompile(local_tryparse, (Type{Union{$T,Missing}}, String))
    end
end

precompile(StationXML.read, (String,))
precompile(readstring, (String,))


#=
    Merging and appending
=#
for T in (Network, Station, Channel)
    precompile(_time_ranges_overlap, (T, T))
end
precompile(_merge!, (Nothing, FDSNStationXML, FDSNStationXML, Bool))
precompile(_merge!, (FDSNStationXML, Network, Network, Bool))
precompile(_merge!, (Network, Station, Station, Bool))
precompile(Base.append!, (Network, Network))
precompile(Base.append!, (FDSNStationXML, FDSNStationXML))
precompile(Base.merge, (FDSNStationXML, FDSNStationXML))
precompile(Base.merge, (FDSNStationXML, FDSNStationXML, FDSNStationXML))
precompile(Base.merge!, (FDSNStationXML, FDSNStationXML))
precompile(Base.merge!, (FDSNStationXML, FDSNStationXML, FDSNStationXML))
