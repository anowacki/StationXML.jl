# Base types which do not depend on others

"By default, types do not have attributes"
attribute_fields(::Type) = ()
attribute_fields(::Type{Union{Missing,T}}) where T = attribute_fields(T)

"By default, all fields are element fields, apart from the attribute fields"
element_fields(::Type{T}) where T = (field for field in fieldnames(T) if field ∉ attribute_fields(T))
element_fields(::Type{Union{Missing,T}}) where T = element_fields(T)

# TODO: Find a reliable way to 'inherit' from versions of
# uncertaintyDouble and floatType and so on without manually repeating
# fields

# Types derived from FloatType, with an uncertaintyDouble group,
# which have units which are optional but can take only one value,
# and whose values potentially must lie within a range.
for (name, unit, docstring, range) in (
        (:Second, "SECONDS", "A length of time in seconds.", nothing),
        (:Voltage, "VOLTS", "A measurement of voltage.", nothing),
        (:Angle, "DEGREES", "An angle given in degrees.", (-360, 360)),
        (:Azimuth, "DEGREES", "An azimuth measured clockwise from local north, in degrees.", (0, 360)),
        (:Dip, "DEGREES", "Angle measured downwards from local horizontal, in degrees.", (-90, 90)),
        (:ClockDrift, "SECONDS/SAMPLE", "A tolerance value, measured in " *
            "seconds per sample, used as a threshold for time error detection " *
            "in data from the channel.", (0, Inf)),
        )
    name_string = String(name)
    optional_value_check = :()
    optional_constructor_value_check = :()
    if range !== nothing
        val1, val2 = range
        error_string = "value of $name_string must be in range $val1 to $val2"
        optional_constructor_value_check = :($val1 <= value <= $val2 || throw(ArgumentError($error_string)))
        optional_value_check = :(
            if field === :value
                $val1 <= value <= $val2 || throw(ArgumentError($error_string))
            end
        )
    end
    @eval begin
        """
            $($name_string)(value)
            $($name_string)(; value, plus_error=missing, minus_error=missing, unit=missing)

        $($docstring)

        # List of fields
        $(DocStringExtensions.TYPEDFIELDS)
        """
        mutable struct $name
            "Value of observation"
            value::Float64
            "Absolute error in the positive direction."
            plus_error::M{Float64}
            "Absolute error in the negative direction (i.e., this value should be positive)."
            minus_error::M{Float64}
            "Units of observation (can only be `\"$($unit)\"`)."
            unit::M{String}

            function $(name)(value, plus_error=missing, minus_error=missing, unit=missing)
                $optional_constructor_value_check
                if unit !== missing
                    unit == $unit || throw(ArgumentError("units of $($name_string) must be `\"$($unit)\"`"))
                end
                new(value, plus_error, minus_error, unit)
            end
        end

        # Keyword constructor
        $(name)(; value, plus_error=missing, minus_error=missing, unit=missing) =
            $(name)(value, plus_error, minus_error, unit)

        attribute_fields(::Type{$name}) = (:plus_error, :minus_error, :unit)
        element_fields(::Type{$name}) = ()

        # Enforce the value of unit when using setproperty!
        function Base.setproperty!(x::$name, field::Symbol, value)
            if field === :unit
                if value !== missing
                    value == $unit || throw(ArgumentError("units of $($name_string) must be `\"$($unit)\"`"))
                    setfield!(x, :unit, String(value))
                else
                    setfield!(x, :unit, missing)
                end
            else
                $optional_value_check
                value_conv = convert(Union{Missing,Float64}, value)
                setfield!(x, field, value_conv)
            end
            value
        end

        # Parse an EzXML.Node as this type
        function parse_node(::Type{$name}, node::EzXML.Node, warn::Bool=false)::$name
            val = $(name)(parse(Float64, node.content))
            for att in EzXML.eachattribute(node)
                if att.name == "plusError"
                    val.plus_error = parse(Float64, att.content)
                elseif att.name == "minusError"
                    val.minus_error = parse(Float64, att.content)
                elseif att.name == "unit"
                    val.unit = att.content
                else
                    warn && @warn("Unexpected attribute \"$(att.name)\" for $($name_string)")
                end
            end
            val
        end

        # Conversion
        Base.convert(::Type{$name}, value::Number) = $(name)(value)
        Base.convert(::Type{N}, typ::$name) where {N<:Number} =  N(typ.value)
    end
end

# Types derived from FloatType, with an uncertaintyDouble group,
# and which have a default unit whose value is not enforced(!).
for (name, unit, docstring) in (
        (:Distance, "METERS", "A measure of distance, depth or elevation.  By default, units are in m."),
        )
    name_string = String(name)
    @eval begin
        """
            $($name_string)(value)
            $($name_string)(; value, plus_error=missing, minus_error=missing, unit=$($unit))

        $($docstring)

        # List of fields
        $(DocStringExtensions.TYPEDFIELDS)
        """
        mutable struct $name
            "Value of observation."
            value::Float64
            "Absolute error in the positive direction."
            plus_error::M{Float64}
            "Absolute error in the negative direction (i.e., this value should be positive)."
            minus_error::M{Float64}
            "Units of observation (defaults to `\"$($unit)\"`)."
            unit::M{String}

            $(name)(value, plus_error=missing, minus_error=missing, unit=$unit) =
                new(value, plus_error, minus_error, unit)
        end

        $(name)(; value, plus_error=missing, minus_error=missing, unit=$unit) =
            $(name)(value, plus_error, minus_error, unit)

        attribute_fields(::Type{$name}) = (:plus_error, :minus_error, :unit)
        element_fields(::Type{$name}) = ()

        function parse_node(::Type{$name}, node::EzXML.Node, warn::Bool=false)::$name
            val = $(name)(parse(Float64, node.content))
            for att in EzXML.eachattribute(node)
                if att.name == "plusError"
                    val.plus_error = parse(Float64, att.content)
                elseif att.name == "minusError"
                    val.minus_error = parse(Float64, att.content)
                elseif att.name == "unit"
                    val.unit = att.content
                else
                    warn && @warn("Unexpected attribute \"$(att.name)\" for $($name_string)")
                end
            end
            val
        end
    end
end

# Types from FloatType, without an uncertaintyDouble group,
# and which have an optional unit whose value can only be one thing
for (name, unit, docstring) in (
        (:Frequency, "HERTZ", "Frequency measured in Hz."),
        (:SampleRate, "SAMPLES/S", "Sample rate measured in samples per second."),
        )
    name_string = String(name)
    error_string = "units of $name_string can only be `\"$unit\"`"
    @eval begin
        """
            $($name_string)(value, unit=$($unit))
            $($name_string)(; value, unit=$($unit))

        $($docstring)

        # List of fields
        $(DocStringExtensions.TYPEDFIELDS)
        """
        mutable struct $name
            "Value in Hz."
            value::Float64
            "Units (must be `\"$($unit)\"`)."
            unit::M{String}

            function $(name)(value, unit=missing)
                if unit !== missing
                    unit == $unit || throw(ArgumentError($error_string))
                end
                new(value, unit)
            end
        end

        $(name)(; value, unit=missing) = $(name)(value, unit)

        attribute_fields(::Type{$name}) = (:unit,)
        element_fields(::Type{$name}) = ()

        function Base.setproperty!(x::$name, field::Symbol, value)
            if field === :unit
                if value !== missing
                    value == $unit || throw(ArgumentError($error_string))
                    setfield!(x, :unit, String(value))
                else
                    setfield!(x, :unit, missing)
                end
            elseif field === :value
                setfield!(x, :value, convert(Float64, value))
            else
                error("type $($name_string) has no field $field")
            end
            value
        end

        function parse_node(::Type{$name}, node::EzXML.Node, warn::Bool=false)::$name
            val = $(name)(parse(Float64, node.content))
            for att in EzXML.eachattribute(node)
                if att.name == "unit"
                    val.unit = att.content
                else
                    warn && @warn("Unexpected attribute \"$(att.name)\" for $($name_string)")
                end
            end
            val
        end
    end
end

# Latitude and longitude types, which have an uncertaintyDouble group,
# an optional unit which can be only one thing,
# plus an additional field for the datum.
for (name, range) in (
        (:Latitude, (-90, 90)),
        (:Longitude, (-180, 180)),
        )
    name_string = String(name)
    value_error_string = "value for $name must be in range $(range[1])° to $(range[2])°"
    unit_error_string = "units for $name must be `\"DEGREES\"`"
    @eval begin
        """
            $($name_string)(value, plus_error, minus_error, unit="DEGREES", datum="WGS84")
            $($name_string)(; value, plus_error=missing, minus_error=missing, unit="DEGREES", datum="WGS84")

        $($name_string) coordinate, measured in degrees.  The `datum` can be specified
        and defaults to `"WGS84"`.

        # List of fields
        $(DocStringExtensions.TYPEDFIELDS)
        """
        mutable struct $name
            "Coordinate in degrees."
            value::Float64
            "Absolute error in the positive direction."
            plus_error::M{Float64}
            "Absolute error in the negative direction (i.e., this value should be positive)."
            minus_error::M{Float64}
            "Units of observation (must be `\"DEGREES\"`)."
            unit::M{String}
            "Spheroid datum on which coordinate is measured."
            datum::M{String}

            function $(name)(value, plus_error=missing, minus_error=missing,
                    unit=missing, datum="WGS84")
                $(range[1]) <= value <= $(range[2]) ||
                    throw(ArgumentError($value_error_string))
                if unit !== missing
                    unit == "DEGREES" || throw(ArgumentError($value_error_string))
                end
                if datum !== missing
                    datum = xs_nmtoken_or_throw(datum)
                end
                new(value, plus_error, minus_error, unit, datum)
            end
        end

        # Keyword constructor
        $(name)(; value, plus_error=missing, minus_error=missing, unit=missing, datum="WGS84") =
            $(name)(value, plus_error, minus_error, unit, datum)

        attribute_fields(::Type{$name}) = (:plus_error, :minus_error, :unit, :datum)
        element_fields(::Type{$name}) = ()

        function Base.setproperty!(coord::$name, field::Symbol, value)
            if field === :unit
                if value !== missing
                    value == "DEGREES" || throw(ArgumentError($unit_error_string))
                    setfield!(coord, :unit, String(value))
                else
                    setfield!(coord, :unit, missing)
                end
            elseif field === :datum && value !== missing
                value = xs_nmtoken_or_throw(value)
                setfield!(coord, :datum, String(value))
            elseif field === :value
                $(range[1]) <= value <= $(range[2]) || throw(ArgumentError($value_error_string))
                setfield!(coord, :value, convert(Float64, value))
            else
                setfield!(coord, field, convert(Union{Missing,Float64}, value))
            end
            value
        end

        function parse_node(::Type{$name}, node::EzXML.Node, warn::Bool=false)::$name
            val = $(name)(parse(Float64, node.content))
            for att in EzXML.eachattribute(node)
                if att.name == "plusError"
                    val.plus_error = parse(Float64, att.content)
                elseif att.name == "minusError"
                    val.minus_error = parse(Float64, att.content)
                elseif att.name == "unit"
                    val.unit = att.content
                elseif att.name == "datum"
                    val.datum = att.content
                else
                    warn && @warn("Unexpected attribute \"$(att.name)\" for $($name_string)")
                end
            end
            val
        end

    end
end

"""
    FrequencyRange

Variation in decibels within the specified range.

Defines a pass band in Hertz (`frequency_start` and `frequency_end`) in which a
`SensitivityValue` is valid within the
number of decibels specified in `frequency_db_variation`.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct FrequencyRange
    frequency_start::Float64
    frequency_end::Float64
    frequency_db_variation::Float64
end

"""
    FloatNoUnit(value, plus_error, minus_error)

Representation of a floating-point number of a unitless quantity.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct FloatNoUnit
    "Value of observation."
    value::Float64
    "Absolute error in the positive direction."
    plus_error::M{Float64} = missing
    "Absolute error in the negative direction (i.e., this value should be positive)."
    minus_error::M{Float64} = missing
    FloatNoUnit(value, plus_error=missing, minus_error=missing) = new(value, plus_error, minus_error)
end

attribute_fields(::Type{FloatNoUnit}) = (:plus_error, :minus_error)
element_fields(::Type{FloatNoUnit}) = ()

function parse_node(::Type{FloatNoUnit}, node::EzXML.Node, warn::Bool=false)
    val = FloatNoUnit(parse(Float64, node.content))
    for att in EzXML.eachattribute(node)
        if att.name == "plusError"
            val.plus_error = parse(Float64, att.content)
        elseif att.name == "minusError"
            val.minus_error = parse(Float64, att.content)
        else
            warn && @warn("Unexpected attribute\"$(att.name)\" for FloatNoUnit")
        end
    end
    val
end


"""
    Float(value, plus_error=missing, minus_error=missing, unit=missing)
    Float(; value, plus_error=missing, minus_error=missing, unit=missing)

Representation of floating-point numbers used as measurements.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct Float
    "Value of observation"
    value::Float64
    "Absolute error in the positive direction."
    plus_error::M{Float64} = missing
    "Absolute error in the negative direction (i.e., this value should be positive)."
    minus_error::M{Float64} = missing
    "Units of observation."
    unit::M{String} = missing
    Float(value, plus_error=missing, minus_error=missing, unit=missing) = new(value, plus_error, minus_error, unit)
end

attribute_fields(::Type{Float}) = (:plus_error, :minus_error, :unit)
element_fields(::Type{Float}) = ()

function parse_node(::Type{Float}, node::EzXML.Node, warn::Bool=false)
    val = Float(parse(Float64, node.content))
    for att in EzXML.eachattribute(node)
        if att.name == "plusError"
            val.plus_error = parse(Float64, att.content)
        elseif att.name == "minusError"
            val.minus_error = parse(Float64, att.content)
        elseif att.name == "unit"
            val.unit = att.content
        else
            warn && @warn("Unexpected attribute\"$(att.name)\" for FloatNoUnit")
        end
    end
    val
end

"""
    ExternalReference(uri, description)
    ExternalReference(; uri, description)

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct ExternalReference
    uri::String
    description::String
end

"""
    Nominal

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct Nominal
    value::String
    function Nominal(value)
        value in ("NOMINAL", "CALCULATED") ||
            throw(ArgumentError("Nominal must be 'NOMINAL' or 'CALCULATED'"))
        new(value)
    end
end

"""
    Email(value)

An email address, restricted to have the correct form.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct Email
    value::String
    function Email(value)
        occursin(r"^[\w\.\-_]+@[\w\.\-_]+$", value) ||
            throw(ArgumentError("email address not in correct form"))
        new(value)
    end
end

"""
    PhoneNumber(country_code, area_code, phone_number, description)
    PhoneNumber(; country_code=missing, area_code, phone_number, description=missing)

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct PhoneNumber
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

"""
    Person(name, agency, email, phone)
    Person(; name=String[], agency=String[], email=Email[], phone=PhoneNumber[])

Representation of a person's contact information. A person can belong
to multiple agencies and have multiple email addresses and phone numbers.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct Person
    name::Vector{String} = String[]
    agency::Vector{String} = String[]
    email::Vector{Email} = Email[]
    phone::Vector{PhoneNumber} = PhoneNumber[]
end

"""
    Site(name, description, town, county, region, country)
    Site(; name, description=missing, town=missing, county=missing, region=missing, country=missing)

Description of a site location using name and optional geopolitical
boundaries (country, city, etc.).

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct Site
    "The commonly used name of this station, equivalent to the SEED blockette 50, field 9."
    name::String
    "A longer description of the location of this station, e.g.
	 'NW corner of Yellowstone National Park' or '20 miles west of Highway 40'."
    description::M{String} = missing
    "The town or city closest to the station."
    town::M{String} = missing
    county::M{String} = missing
    "The state, province, or region of this site."
    region::M{String} = missing
    country::M{String} = missing
end

"""
    Comment(value, begin_effective_time, end_effective_time, author)
    Comment(; value, begin_effective_time=missing, end_effective_time=missing, author=Person[])

Container for a comment or log entry. Corresponds to SEED blockettes 31, 51 and 59.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct Comment
    value::String
    begin_effective_time::M{DateTime} = missing
    end_effective_time::M{DateTime} = missing
    author::Vector{Person} = Person[]
    id::M{Int} = missing
end

Comment(value) = Comment(value, missing, missing, Person[], missing)

element_fields(::Type{Comment}) = (:value, :begin_effective_time, :end_effective_time, :author)
attribute_fields(::Type{Comment}) = (:id,)

"""
    SampleRateRatio(number_samples, number_seconds)

Sample rate expressed as number of samples in a number of seconds.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct SampleRateRatio
    number_samples::Int
    number_seconds::Int
end

"""
    PoleZero(real, imaginary)
    PoleZero(; real, imaginary)

Complex numbers used as poles or zeros in channel response.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct PoleZero
    real::FloatNoUnit
    imaginary::FloatNoUnit
    number::Int
end

attribute_fields(::Type{PoleZero}) = (:number,)

@enumerated_struct(RestrictedStatus, ("open", "closed", "partial"))

"""
    Units(name, description=missing)
    Units(; name, description=missing)

A type to document units.  Corresponds to SEED blockette 34.

Conversion is defined between `Units` and subtypes of `AbstractString`.
This means that is is possible to set fields of types which are
`Units` just by passing a `String` (though note that no `description`
field is set).

### For example
```
julia> StationXML.ResponseList(input_units="M/S", output_units="V")
StationXML.ResponseList
  description: Missing missing
  input_units: StationXML.Units
  output_units: StationXML.Units
  resource_id: Missing missing
  name: Missing missing
  response_list_element: Array{StationXML.ReponseListElement}((0,))
```

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct Units
    "Name of units, e.g. `\"M/S\"`, `\"V\"`, `\"PA\"`."
    name::String
    "Name of units, e.g. \"Velocity in meters per second\", \"Volts\", \"Pascals\"."
    description::M{String} = missing
end

Units(name) = Units(name, missing)

Base.convert(::Type{Units}, s::AbstractString) = Units(s)
Base.convert(::Type{S}, units::Units) where {S<:AbstractString} = S(units.name)

# """The BaseFilterType is derived by all filters"""
@pour BaseFilter begin
    # @pour creates a macro, @BaseFilter, with which to insert the contents later
    # to mix in the following fields.  Declare like:
    #   struct X @BaseFilter; f1; f2 end
    description::M{String} = missing
    input_units::Units
    output_units::Units
    resource_id::M{String} = missing
    name::M{String} = missing
end

"Attributes of the BaseFilter fields"
const BASE_FILTER_ATTRIBUTES = (:resource_id, :name)

"Markdown text to append to docstring of types which include the `BaseFilter` fields"
const BASE_FILTER_FIELDS_DOCSTRING = """
- `description::Union{String,Missing}`
  Free description.  Default: missing
- `input_units::Units`
  The units of the data as input from the perspective of data
  acquisition. After correcting data for this response, these would be the
  resulting units.
- `output_units::Units
  The units of the data as output from the perspective of data
  acquisition. These would be the units of the data prior to correcting for
  this response.
- `resource_id::Union{String,Missing}`
  Same meaning as `[Equipment](@ref StationXML.Equipment).resource_id`.
  Default: missing
- `name::Union{String,Missing}`
  A name given to this filter.  Default: missing

"""

# """
# A base node type for derivation from: Network, Station and Channel types.
# """
@pour BaseNode begin
    description::M{String} = missing
    comment::Vector{Comment} = Comment[]
    code::String
    start_date::M{DateTime} = missing
    end_date::M{DateTime} = missing
    restricted_status::M{RestrictedStatus} = missing
    # "A code used for display or association, alternate to the SEED-compliant code."
    alternate_code::M{String} = missing
    # "A previously used code if different from the current code."
    historical_code::M{String} = missing
end

"Attributes of the BaseNode fields"
const BASE_NODE_ATTRIBUTES = (:code, :start_date, :end_date,
    :restricted_status, :alternate_code, :historical_code)

"Markdown text to append to docstring of types which include the `BaseNode` fields"
const BASE_NODE_FIELDS_DOCSTRING = """"
- `description::Union{String,Missing}`
  Description of the site (free text).  Default: missing
- `comment::Vector{Comment}`
  Set of [`Comment`](@ref StationXML.Comment)s.  Default: Comment[]
- `code::String`
  Code for this instance.
- `start_date::Union{DateTime,Missing}`
  Beginning time of operation.  Deafult: missing
- `end_date::Union{DateTime,Missing}`
  End time of operation.  Default: missing
- `restricted_status::Union{RestrictedStatus,Missing}`
  A description of the access status of this instance.
  See [`RestrictedStatus`](@ref StationXML.RestrictedStatus)
  Default missing
- `alternate_code::Union{String,Missing}`
  A code used for display or association, alternate to the SEED-compliant code.
  Default: missing
- `historical_code::Union{String,Missing}`
  A previously used code if different from the current code.  Default: missing
"""
