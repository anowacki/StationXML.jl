# Base types which do not depend on others

"""Variation in decibels within the specified range."""
@with_kw struct FrequencyRange
    frequency_start::Float64
    frequency_end::Float64
    frequency_db_variation::Float64
end

"""Expressing uncertainties or errors with a positive and a negative
component. Both values should be given as positive integers [doubles?—AN],
but minus_error is understood to actually be negative."""
@with_kw struct Uncertainty
    plus_error::Float64
    minus_error::Float64
end

"""Extension of FloatType for distances, elevations, and depths."""
@with_kw struct Distance
    unit::M{String} = "METERS"
    uncertainty::M{Uncertainty} = missing
end

@with_kw struct ExternalReference
    uri::String
    description::String
end

@with_kw struct Nominal
    value::String
    function Nominal(value)
        value in ("NOMINAL", "CALCULATED") ||
            throw(ArgumentError("Nominal must be 'NOMINAL' or 'CALCULATED'"))
        new(value)
    end
end

@with_kw struct Email
    value::String
    function Email(value)
        occursin(r"^[\w\.\-_]+@[\w\.\-_]+$", value) ||
            throw(ArgumentError("email address not in correct form"))
        new(value)
    end
end

@with_kw struct PhoneNumber
    country_code::M{Int} = missing
    area_code::Int
    phone_number::String
    description::M{String} = missing
    function PhoneNumber(country_code, area_code, phone_number, description)
        occursin(r"[0-9]+-[0-9]+$", phone_number) ||
            throw(ArgumentError("phone_number not in correct form"))
        new(country_code, area_code, phone_number, description)
    end
end

"""Representation of a person's contact information. A person can belong
to multiple agencies and have multiple email addresses and phone numbers."""
@with_kw struct Person
    name::Vector{String} = String[]
    agency::Vector{String} = String[]
    email::Vector{Email} = Email[]
    phone::Vector{PhoneNumber} = PhoneNumber[]
end

"""Description of a site location using name and optional geopolitical
boundaries (country, city, etc.)."""
@with_kw struct Site
    "The commonly used name of this station, equivalent to the SEED blockette 50, field 9."
    name::String
    "A longer description of the location of this station, e.g.
	 'NW corner of Yellowstone National Park' or '20 miles west of Highway 40.'"
    description::M{String} = missing
    "The town or city closest to the station."
    town::M{String} = missing
    county::M{String} = missing
    "The state, province, or region of this site."
    region::M{String} = missing
    country::M{String} = missing
end

"""Container for a comment or log entry. Corresponds to SEED blockettes 31, 51 and 59."""
@with_kw struct Comment
    value::String
    begin_effective_time::M{DateTime} = missing
    end_effective_time::M{DateTime} = missing
    author::Vector{Person} = Person[]
end

"""Sample rate expressed as number of samples in a number of seconds."""
@with_kw struct SampleRateRatio
    number_samples::Float64
    number_seconds::Float64
end

"""Complex numbers used as poles or zeros in channel response."""
@with_kw struct PoleZero
    real::Float64
    imaginary::Float64
end

@with_kw struct RestrictedStatus
    value::String
    function RestrictedStatus(value)
        value in ("open", "closed", "partial") ||
            throw(ArgumentError("RestrictedStatus must be 'open', 'partial', or 'closed'"))
        new(value)
    end
end

"""A type to document units.  Corresponds to SEED blockette 34."""
@with_kw struct Units
    name::String
    "Name of units, e.g. \"Velocity in meters per second\", \"Volts\", \"Pascals\"."
    description::M{String} = missing
end

# """The BaseFilterType is derived by all filters"""
@pour BaseFilter begin
    # @pour creates a macro, @BaseFilter, with which to insert the contents later
    # to mix in the following fields.  Declare like:
    #   struct X @BaseFilter; f1; f2 end
    description::M{String} = missing
    # "The units of the data as input from the perspective of data
    #  acquisition. After correcting data for this response, these would be the
    #  resulting units."
    input_units::Units
    # "The units of the data as output from the perspective of data
    #  acquisition. These would be the units of the data prior to correcting for
    #  this response."
    output_units::Units
    # "Same meaning as Equipment.resource_id"
    resource_id::M{String} = missing
    # "A name given to this filter."
    name::M{String} = missing
end

# """
# A base node type for derivation from: Network, Station and Channel types.
# """
@pour BaseNode begin
    description::M{String} = missing
    comment::Vector{Comment} = Comment[]
    code::String
    start_date::DateTime
    end_date::DateTime
    restricted_status::M{RestrictedStatus} = missing
    # "A code used for display or association, alternate to the SEED-compliant code."
    alternate_code::M{String} = missing
    # "A previously used code if different from the current code."
    historical_code::M{String} = missing
end
