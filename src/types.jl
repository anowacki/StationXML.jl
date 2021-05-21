# Uppermost types in the schema.  Most of these extend the BaseNodeType.
# Since there are only three types in the schema which extend the BaseNodeType,
# we simply reproduce the fields of the BaseNodeType directly within each
# struct.  This allows each field to be documented by DocStringExtensions
# which is not possible using Mixers.@pour.
#
# FIXME: Find a way to allow documented fields to be inserted into a struct.


@enumerated_struct(ChannelType, ("TRIGGERED", "CONTINUOUS", "HEALTH", "GEOPHYSICAL",
            "WEATHER", "FLAG", "SYNTHESIZED", "INPUT", "EXPERIMENTAL",
            "MAINTENANCE", "BEAM"))

"""
    Channel

A channel is a time series recording of a component of some observable,
often colocated with other channels at the same location of a station.

Equivalent to SEED blockette 52 and parent element for the related the response blockettes.

!!! note
    The presence of a `sample_rate_ratio` without a `sample_rate` field is
    not allowed in the standard, but it permitted by StationXML.jl.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct Channel
    # BaseNodeType fields
    description::M{String} = missing
    "Persistent identifier for this `Channel`"
    identifier::Vector{Identifier} = Identifier[]
    comment::Vector{Comment} = Comment[]
    "A description of time series data availablility for this `Channel`"
    data_availability::M{DataAvailability} = missing
    "Channel's code (e.g., `\"BHE\"`)."
    code::String
    "Start date of operation of this channel of the containing station."
    start_date::M{DateTime} = missing
    "End date of operation of this channel.  May be `missing`."
    end_date::M{DateTime} = missing
    "A data source identifier in URI form"
    source_id::M{String} = missing
    "Information on whether the data in this channel are restricted, open,
     or otherwise.  (See [`RestrictedStatus`](@ref StationXML.RestrictedStatus).)"
    restricted_status::M{RestrictedStatus} = missing
    "A code used for display or association, alternate to the SEED-compliant code."
    alternate_code::M{String} = missing
    "A previously used code if different from the current code."
    historical_code::M{String} = missing
    # end of BaseNodeType fields
    "URI of any type of external report, such as data quality reports."
    external_reference::Vector{ExternalReference} = ExternalReference[]
    "Latitude coordinate of this channel's sensor."
    latitude::Latitude
    "Longitude coordinate of this channel's sensor."
    longitude::Longitude
    "Elevation of the sensor."
    elevation::Distance
    "The local depth or overburden of the instrument's location. For downhole
     instruments, the depth of the instrument under the surface ground level.
     For underground vaults, the distance from the instrument to the local ground level above."
    depth::Distance
    "Azimuth of the sensor in degrees from north, clockwise."
    azimuth::M{Azimuth} = missing
    "Dip of the instrument in degrees, down from horizontal."
    dip::M{Dip} = missing
    "Elevation of the water surface in meters for underwater sites, where 0 is sea level."
    water_level::M{Float} = missing
    "The type of data this channel collects. Corresponds to
     channel flags in SEED blockette 52. The SEED volume producer could
     use the first letter of an Output value as the SEED channel flag."
    type::Vector{ChannelType} = ChannelType[]
    # SampleRateGroup fields
    "Sampling rate of the channel in samples/s.  If `sample_rate_ratio` is
     also included, then `sample_rate` is more definitive."
    sample_rate::M{SampleRate} = missing
    "Sampling rate of the channel in number of samples per number of seconds."
    sample_rate_ratio::M{SampleRateRatio} = missing
    # end of SampleRateGroup fields
    "The storage format of the recorded data (e.g. SEED).
     **Removed in StationXML v1.1.**"
    storage_format::M{String} = missing
    "A tolerance value, measured in seconds per sample, used as a threshold for time
     error detection in data from the channel."
    clock_drift::M{ClockDrift} = missing
    calibration_units::M{Units} = missing
    sensor::M{Equipment} = missing
    pre_amplifier::M{Equipment} = missing
    data_logger::M{Equipment} = missing
    equipment::Vector{Equipment} = Equipment[]
    "The transfer function describing how ground motion is translated into
    digital counts."
    response::M{Response} = missing
    "Code defining the location of the channel (may be empty)."
    location_code::String
end

"""
    attribute_fields(T::Type)

Return the fields of type `T` which are stored as attributes in the
StationXML specification
"""
attribute_fields(::Type{Channel}) = (BASE_NODE_ATTRIBUTES..., :location_code)

"""
    removed_fields(T::Type)

Return the fields of type `T` which are no longer present in the latest StationXML
version.
"""
removed_fields(::Type{Channel}) = (:storage_format,)

"""
    Station

This type represents a Station epoch. It is common to only have a
single station epoch with the station's creation and termination dates as the epoch
start and end dates.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct Station
    # BaseNodeType fields
    description::M{String} = missing
    "Persistent identifier for this `Station`"
    identifier::Vector{Identifier} = Identifier[]
    comment::Vector{Comment} = Comment[]
    "A description of time series data availablility for this `Station`"
    data_availability::M{DataAvailability} = missing
    "Station's code, e.g. `\"ANMO\"`."
    code::String
    "Start date of operation of the station."
    start_date::M{DateTime} = missing
    "End date of operation of the station."
    end_date::M{DateTime} = missing
    "A data source identifier in URI form"
    source_id::M{String} = missing
    "Information on whether the data from this station are restricted, open,
     or otherwise.  (See [`RestrictedStatus`](@ref StationXML.RestrictedStatus).)"
    restricted_status::M{RestrictedStatus} = missing
    "A code used for display or association, alternate to the SEED-compliant code."
    alternate_code::M{String} = missing
    "A previously used code if different from the current code."
    historical_code::M{String} = missing
    # end of BaseNodeType fields
    "Latitude coordinate of station in degrees."
    latitude::Latitude
    "Longitude coordinate of station in degrees."
    longitude::Longitude
    "Elevation of station above the local reference level in m."
    elevation::Distance
    "These fields describe the location of the station
     using geopolitical entities (country, city, etc.)."
    site::Site
    "Elevation of the water surface in meters for underwater sites, where 0 is sea level."
    water_level::M{Float} = missing
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
    "Date and time (UTC) when the station was first installed.
     **Note that this field is mandatory in StationXML v1.0, but optional
     in StationXML v1.1.**"
    creation_date::M{DateTime} = missing
    # FIXME: Test whether blank values need to be handled as a M{DateTime} field
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
    "Set of [`Channel`](@ref StationXML.Channel)s contained within this
     `Network` and returned as part of a request."
    channel::Vector{Channel} = Channel[]
end

attribute_fields(::Type{Station}) = (BASE_NODE_ATTRIBUTES...,)

"""
    Network

This type represents the Network layer, all station metadata is
contained within this element. The official name of the network or other descriptive
information can be included in the Description element. The Network can contain 0 or
more Stations.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct Network
    # BaseNodeType fields
    description::M{String} = missing
    "Persistent identifier for this `Network`"
    identifier::Vector{Identifier} = Identifier[]
    comment::Vector{Comment} = Comment[]
    "A description of time series data availablility for this `Network`"
    data_availability::M{DataAvailability} = missing
    "Network's code (e.g., `\"IU\"`)."
    code::String
    start_date::M{DateTime} = missing
    end_date::M{DateTime} = missing
    "A data source identifier in URI form"
    source_id::M{String} = missing
    "Information on whether the data in this network are restricted, open,
     or otherwise.  (See [`RestrictedStatus`](@ref StationXML.RestrictedStatus).)"
    restricted_status::M{RestrictedStatus} = missing
    "A code used for display or association, alternate to the SEED-compliant code."
    alternate_code::M{String} = missing
    "A previously used code if different from the current code."
    historical_code::M{String} = missing
    # end of BaseNodeType fields
    "An operating agency and associated contact persons."
    operator::Vector{Operator} = Operator[]
    "The total number of stations contained in this
	 network, including inactive or terminated stations."
    total_number_stations::M{Int} = missing
    "The total number of stations in this network that
	 were selected by the query that produced this document, even if the
	 stations do not appear in the document. (This might happen if the
	 user wants a document that contains only information at
	 the Network level.)"
    selected_number_stations::M{Int} = missing
    "List of [`Station`](@ref StationXML.Station)s within a network included
     in this query."
    station::Vector{Station} = Station[]

    function Network(description, identifier, comment, data_availability, code,
            start_date, end_date,
            source_id, restricted_status, alternate_code, historical_code, operator,
            total_number_stations, selected_number_stations, station)
        if total_number_stations !== missing
            total_number_stations >= 0 ||
                throw(ArgumentError("total_number_stations must be 0 or more"))
        end
        if selected_number_stations !== missing
            selected_number_stations >= 0 ||
                throw(ArgumentError("selected_number_stations must be 0 or more"))
        end
        new(description, identifier, comment, data_availability, code, start_date, end_date,
            source_id, restricted_status, alternate_code, historical_code, operator,
            total_number_stations, selected_number_stations, station)
    end
end

attribute_fields(::Type{Network}) = (BASE_NODE_ATTRIBUTES...,)

"""
    FDSNStationXML

Top-level type for Station XML. Required field are `source` (network ID
of the institution sending the message), `created` (creation time of the document)
and one or more `Network`s containers.

This corresponds to the schema's RootType.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct FDSNStationXML
    "Network ID of the institution sending the message."
    source::String
    "Name of the institution sending this message."
    sender::M{String} = missing
    "Name of the software module that generated this document.
     [This differs from the StationXML schema because `module` is a reserved
     word in Julia.]"
    module_name::M{String} = missing
    "This is the address of the query that generated the document,
     or, if applicable, the address of the software that generated this document.
     Note that this string is not enforced to be a valid URI."
    module_uri::M{String} = missing
    "Date of creation of this StationXML record."
    created::DateTime
    "Set of [`Network`](@ref StationXML.Network)s contained within this
     document."
    network::Vector{Network} = Network[]
    "Version of the StationXML schema used by these data."
    schema_version::String
end

attribute_fields(::Type{FDSNStationXML}) = (:schema_version,)

"Types which should be compared using Base.==="
const COMPARABLE_TYPES = Union{Float64, String, DateTime}

# Hacky way to define == for all the types we create
for name in names(StationXML, all=true)
    name_str = String(name)
    if occursin(r"^[A-Z]", name_str) && !occursin(r"^BASE", name_str)
        name in (:M, :COMPARABLE_TYPES, :StationXML, :Numerator, :Denominator) && continue
        getfield(StationXML, name) isa DataType || continue
        @eval Base.:(==)(a::$name, b::$name)::Bool = a === b || local_equals(a, b)
    end
end

"""Local function to compare all types by each of their fields, apart from the types from
Base we use."""
local_equals(a::T, b::T) where {T<:COMPARABLE_TYPES} = a === b
local_equals(::Missing, ::Missing) = true
local_equals(::COMPARABLE_TYPES, ::Missing) = false
local_equals(::Missing, ::COMPARABLE_TYPES) = false
local_equals(a::T, b::T) where {T} =
    all(local_equals(va, vb) for (va, vb) in zip(all_values(a), all_values(b)))
local_equals(a::T1, b::T2) where {T1,T2} = false
local_equals(a::AbstractArray, b::AbstractArray)::Bool =
    size(a) == size(b) && all(local_equals(aa, bb) for (aa, bb) in zip(a,b))
