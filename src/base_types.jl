# Base types which do not depend on others

"""Variation in decibels within the specified range."""
const FrequencyRange = NamedTuple{(:frequency_start, :frequency_end, :frequency_db_variation),
                                  NTuple{3,Float64}}

"""Expressing uncertainties or errors with a positive and a negative
component. Both values should be given as positive integers [doubles?—AN],
but minus_error is understood to actually be negative."""
const Uncertainty = NamedTuple{(:plus_error,:minus_error), NTuple{2,Float64}}

struct Nominal
    value::String
    function Nominal(value)
        value in ("NOMINAL", "CALCULATED") ||
            throw(ArgumentError("Nominal must be 'NOMINAL' or 'calculated'"))
        new(value)
    end
end

struct Email
    value::String
    function Email(value)
        occursin(r"^[\w\.\-_]+@[\w\.\-_]+$") ||
            throw(ArgumentError("email address not in correct form"))
        new(value)
    end
end

@with_kw struct PhoneNumber
    country_code::M{Int} = missing
    area_code::Int
    phone_number::String
    description::M{String}
    function PhoneNumber(country_code, area_code, phone_number, description)
        occursin(r"[0-9]+-[0-9]+$", phone_number) ||
            throw(ArgumentError("phone_number not in correct form"))
        new(country_code, area_code, phone_number, description)
    end
end

@with_kw struct RestrictedStatus
    value::String
    function RestrictedStatus(value)
        value in ("open", "closed", "partial") ||
            throw(ArgumentError("RestrictedStatus must be 'open', 'partial', or 'closed'"))
        new(value)
    end
end

"A type to document units.  Corresponds to SEED blockette 34."
@with_kw struct Units
    name::String
    "Name of units, e.g. \"Velocity in meters per second\", \"Volts\", \"Pascals\"."
    description::M{String} = missing
end

"The BaseFilterType is derived by all filters"
@with_kw struct BaseFilter
    description::M{String} = missing
    "The units of the data as input from the perspective of data
     acquisition. After correcting data for this response, these would be the
     resulting units."
    input_units::Units
    "The units of the data as output from the perspective of data
     acquisition. These would be the units of the data prior to correcting for
     this response."
    output_units::Units
    "Same meaning as Equipment.resource_id"
    resource_id::M{String} = missing
    "A name given to this filter."
    name::String
end
