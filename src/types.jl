# Uppermost types in the schema.  Most of these extend the BaseNodeType, which
# for each we directly insert into the structs here using @BaseNode, created with @pour.

"""
Equivalent to SEED blockette 52 and parent element for the related the response blockettes.
"""
@with_kw struct Channel
    @BaseNode
    "URI of any type of external report, such as data quality reports."
    external_reference::Vector{ExternalReference} = ExternalReference[]
    "Latitude coordinate of this channel's sensor."
    latitude::Float64
    "Longitude coordinate of this channel's sensor."
    longitude::Float64
    "Elevation of the sensor."
    elevation::Float64
    "The local depth or overburden of the instrument's location. For downhole
     instruments, the depth of the instrument under the surface ground level.
     For underground vaults, the distance from the instrument to the local ground level above."
    depth::Float64
    "Azimuth of the sensor in degrees from north, clockwise."
    azimuth::M{Float64} = missing
    "Dip of the instrument in degrees, down from horizontal"
    dip::M{Float64} = missing
    "The type of data this channel collects. Corresponds to
     channel flags in SEED blockette 52. The SEED volume producer could
     use the first letter of an Output value as the SEED channel flag."
    type::Vector{String} = String[]
    "The storage format of the recorded data (e.g. SEED)."
    storage_format::M{String} = missing
    "A tolerance value, measured in seconds per sample, used as a threshold for time
     error detection in data from the channel."
    clock_drift::M{Float64} = missing
    calibration_units::M{Units} = missing
    sensor::M{Equipment} = missing
    pre_amplifier::M{Equipment} = missing
    equipment::M{Equipment} = missing
    response::M{Response} = missing
    location_code::String
end

"""
This type represents a Station epoch. It is common to only have a
single station epoch with the station's creation and termination dates as the epoch
start and end dates.
"""
@with_kw struct Station
    @BaseNode
    latitude::Float64
    longitude::Float64
    elevation::Distance
    "These fields describe the location of the station
     using geopolitical entities (country, city, etc.)."
    site::Site
    "Type of vault, e.g. WWSSN, tunnel, transportable array, etc."
    vault::M{String} = missing
    "Type of rock and/or geologic formation."
    geology::M{String} = missing
    "Equipment used by all channels at a station."
    equipment::Vector{Equipment} = Equipment[]
    "An operating agency and associated contact persons. If
     there multiple operators, each one should be encapsulated within an
     Operator tag. Since the Contact element is a generic type that
     represents any contact person, it also has its own optional Agency
     element."
    operator::Vector{Operator} = Operator[]
    "Date and time (UTC) when the station was first installed."
    creation_date::DateTime
    # FIXME: Test whether blank values need to handled as a M{DateTime} field
    "Date and time (UTC) when the station was terminated or
     will be terminated. A blank value should be assumed to mean that the
     station is still active."
    termination_date::M{DateTime} = missing
    "Total number of channels recorded at this station."
    total_number_channels::M{Int} = missing
    "Number of channels recorded at this station and
	 selected by the query that produced this document."
    selected_number_channels::M{Int} = missing
    "URI of any type of external report, such as IRIS data
     reports or dataless SEED volumes."
    external_reference::Vector{ExternalReference} = ExternalReference[]
    channel::Vector{Channel} = Channel[]
end

"""
This type represents the Network layer, all station metadata is
contained within this element. The official name of the network or other descriptive
information can be included in the Description element. The Network can contain 0 or
more Stations.
"""
@with_kw struct Network
    @BaseNode
    "The total number of stations contained in this
	 network, including inactive or terminated stations."
    total_number_stations::M{Int} = missing
    "The total number of stations in this network that
	 were selected by the query that produced this document, even if the
	 stations do not appear in the document. (This might happen if the
	 user only wants a document that goes contains only information at
	 the Network level.)"
    selected_number_stations::M{Int} = missing
    station::Vector{Station} = Station[]
end

"""
Top-level type for Station XML. Required field are Source (network ID
of the institution sending the message) and one or more Network containers or one or
more Station containers.

This corresponds to the schema's RootType.
"""
@with_kw struct FDSNStationXML
    "Network ID of the institution sending the message."
    source::String
    "Name of the institution sending this message."
    sender::M{String} = missing
    "Name of the software module that generated this document.
     [This differs from the schema because `module` is reserved in Julia.]"
    module_name::M{String} = missing
    "This is the address of the query that generated the document,
     or, if applicable, the address of the software that generated this document."
    module_uri::M{String} = missing
    created::DateTime
    network::Vector{Network} = Network[]
    schema_version::String
end

"Types which should be compared using Base.=="
const COMPARABLE_TYPES = Union{Missing, Float64, String, DateTime}

for T in (:FDSNStationXML, :Network, :Station, :Channel)
    @eval Base.:(==)(a::T, b::T) where T <: $(T) = a === b ? true : local_equals(a, b)
end

"""Local function to compare all types by each of their fields, apart from the types from
Base we use."""
function local_equals(a::COMPARABLE_TYPES, b::COMPARABLE_TYPES)
    a === missing && b === missing && return true
    a == b
end
function local_equals(a::T1, b::T2) where {T1,T2}
    T1 == T2 ? all(local_equals(getfield(a, f), getfield(b, f)) for f in fieldnames(T1)) : false
end
local_equals(a::AbstractArray, b::AbstractArray) =
    size(a) == size(b) && all(local_equals(aa, bb) for (aa, bb) in zip(a,b))
