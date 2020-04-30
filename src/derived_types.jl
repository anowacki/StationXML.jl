# Types using the base types

"""
    Gain(value, frequency)
    Gain(; value, frequency)

Complex type for sensitivity and frequency ranges. This complex type
can be used to represent both overall sensitivities and individual stage gains. The
`FrequencyRangeGroup` is an optional construct that defines a pass band in Hertz
(`frequency_start` and `frequency_nd`) in which the `SensitivityValue` is valid within the
number of decibels specified in FrequencyDBVariation.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct Gain
    "A scalar that, when applied to the data values, converts the data to different units (e.g. Earth units)."
    value::Float64
    "The frequency (in Hertz) at which the Value is valid."
    frequency::Float64
end

function parse_node(::Type{Gain}, node::EzXML.Node, warn::Bool=false)
    local value, frequency
    for elm in EzXML.eachelement(node)
        if elm.name == "Value"
            value = parse(Float64, elm.content)
        elseif elm.name == "Frequency"
            frequency = parse(Float64, elm.content)
        else
            warn && @warn("unexpected element name \"$(elm.name)\" in Gain")
        end
    end
    Gain(value, frequency)
end

"""
    Sensitivity(value, frequency, input_units, output_units)
    Sensitivity(; value, frequency, input_units, output_units, frequency_start=missing, frequency_end=missing, frequency_db_variation=missing)

Sensitivity and frequency ranges.

Optionally specify a frequency range that defines a pass band in Hertz
`frequency_start` and `frequency_end` in which the `value` is valid within the
number of decibels specified in `frequency_db_variation`.

Note that either all or none of `frequency_start`, `frequency_end` and
`frequency_db_variation` must be specified upon construction.
This is **not** enforced however when mutating the fields of a `Sensitivity`
object.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct Sensitivity
    "A scalar that, when applied to the data values, converts the data to different units (e.g. Earth units)."
    value::Float64
    "The frequency (in Hertz) at which the Value is valid."
    frequency::Float64
    "The units of the data as input from the perspective
	 of data acquisition. After correcting data for this response, these
	 would be the resulting units."
    input_units::Units
    "The units of the data as output from the perspective
	 of data acquisition. These would be the units of the data prior to
	 correcting for this response."
    output_units::Units
    frequency_start::M{Float64} = missing
    frequency_end::M{Float64} = missing
    frequency_db_variation::M{Float64} = missing

    function Sensitivity(value, frequency, input_units, output_units,
            frequency_start, frequency_end, frequency_db_variation)
        freq_group = (frequency_start, frequency_end, frequency_db_variation)
        count(x->x===missing, freq_group) in (0, 3) ||
            throw(ArgumentError("either all or none of $freq_group must be given"))
        new(value, frequency, input_units, output_units,
            frequency_start, frequency_end, frequency_db_variation)
    end
end

"""
    Equipment(; kwargs...)

Sensor equipment installed at a Station.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct Equipment
    type::M{String} = missing
    description::M{String} = missing
    manufacturer::M{String} = missing
    vendor::M{String} = missing
    model::M{String} = missing
    serial_number::M{String} = missing
    installation_date::M{DateTime} = missing
    removal_date::M{DateTime} = missing
    calibration_date::Vector{DateTime} = DateTime[]
    other::M{String} = missing
    "This field contains a string that should serve as a unique
	 resource identifier. This identifier can be interpreted differently depending on
	 the datacenter/software that generated the document. Also, we recommend to use
	 something like GENERATOR:Meaningful ID. As a common behaviour equipment with the
	 same ID should contains the same information/be derived from the same base
	 instruments."
    resource_id::M{String} = missing
end

attribute_fields(::Type{Equipment}) = (:resource_id,)

"""
    Log(; entry=Comment[])

Container for log entries.

!!! note
    The `Log` type appears to be unused in StationXML v1.2 and older.
    It is included here for completeness

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct Log
    entry::Vector{Comment} = Comment[]
end

@enumerated_struct(PZTransferFunction,
    ("LAPLACE (RADIANS/SECOND)", "LAPLACE (HERTZ)", "DIGITAL (Z-TRANSFORM)"))

"""
    PolesZeros

Response: complex poles and zeros. Corresponds to SEED blockette 53.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct PolesZeros
    @BaseFilter
    pz_transfer_function_type::PZTransferFunction
    normalization_factor::Float64 = 1.0
    normalization_frequency::Float64
    zero::Vector{PoleZero} = PoleZero[]
    pole::Vector{PoleZero} = PoleZero[]
end

attribute_fields(::Type{PolesZeros}) = BASE_FILTER_ATTRIBUTES

"""
    NumeratorCoefficient

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct NumeratorCoefficient
    value::Float64
    i::M{Int} = missing
end

attribute_fields(::Type{NumeratorCoefficient}) = (:i,)

function parse_node(::Type{NumeratorCoefficient}, node::EzXML.Node, warn::Bool=false)
    value = parse(Float64, node.content)
    i = missing
    for att in EzXML.eachattribute(node)
        if att.name == "i"
            i = parse(Int, att.content)
        else
            warn && @warn("unexpected attribute $(att.name) for NumeratorCoefficient")
        end
    end
    NumeratorCoefficient(value, i)
end

@enumerated_struct(FIRSymmetry,
    ("NONE", "EVEN", "ODD"))

"""
    FIR(; kwargs...)

Response: FIR filter. Corresponds to SEED blockette 61. FIR filters
are also commonly documented using the CoefficientsType element.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct FIR
    @BaseFilter
    "Symmetry of filter.  Must be one of `\"NONE\"`, `\"EVEN\"` or `\"ODD\"`"
    symmetry::FIRSymmetry
    numerator_coefficient::Vector{NumeratorCoefficient} = NumeratorCoefficient[]
end

attribute_fields(::Type{FIR}) = BASE_FILTER_ATTRIBUTES

@enumerated_struct(CfTransferFunction,
    ("ANALOG (RADIANS/SECOND)", "ANALOG (HERTZ)", "DIGITAL"))

"""
    Coefficients(; kwargs...)

Response: coefficients for FIR filter. Laplace transforms or IIR
filters can be expressed using type as well but the PolesAndZerosType should be used
instead. Corresponds to SEED blockette 54.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct Coefficients
    @BaseFilter
    cf_transfer_function_type::CfTransferFunction
    numerator::Vector{Float64} = Float64[]
    denominator::Vector{Float64} = Float64[]
end

attribute_fields(::Type{Coefficients}) = BASE_FILTER_ATTRIBUTES

"""
    ResponseListElement(frequency, amplitude, phase)

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct ResponseListElement
    frequency::Frequency
    amplitude::Float
    phase::Angle
end

"""
    ResponseList

Response: list of frequency, amplitude and phase values. Corresponds to SEED blockette 55.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct ResponseList
    @BaseFilter
    response_list_element::Vector{ResponseListElement} = ResponseListElement[]
end

attribute_fields(::Type{ResponseList}) = BASE_FILTER_ATTRIBUTES

"""
    Coefficient

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct Coefficient
    "Value of the coefficient (no unit)"
    value::Float64
    "Absolute error in the positive direction."
    plus_error::M{Float64} = missing
    "Absolute error in the negative direction (i.e., this value should be positive)."
    minus_error::M{Float64} = missing
    "Number of the coefficient"
    number::M{Int} = missing

    function Coefficient(value, plus_error, minus_error, number)
        number !== missing && number < 0 &&
            throw(ArgumentError("number must be 0 or greater"))
        new(value, plus_error, minus_error, number)
    end
end

attribute_fields(::Type{Coefficient}) = (:plus_error, :minus_error, :number)
element_fields(::Type{Coefficient}) = ()

function parse_node(::Type{Coefficient}, node::EzXML.Node, warn::Bool=false)
    value = parse(Float64, node.content)
    local number
    plus_error = minus_error = missing
    for att in EzXML.eachattribute(node)
        field = transform_name(att.name)
        if field === :number
            number = parse(Int, att.content)
        elseif field === :plus_error
            plus_error = parse(Float64, att.content)
        elseif field === :minus_error
            minus_error = parse(Float64, att.content)
        else
            warn && @warn("unexpected attribute $(att.name) for NumeratorCoefficient")
        end
    end
    Coefficient(value, plus_error, minus_error, number)
end

@enumerated_struct(Approximation, ("MACLAURIN",))

"""
    Polynomial

Response: expressed as a polynomial (allows non-linear sensors to be
described). Corresponds to SEED blockette 62. Can be used to describe a stage of
acquisition or a complete system.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct Polynomial
    @BaseFilter
    approximation_type::Approximation = Approximation("MACLAURIN")
    frequency_lower_bound::Frequency
    frequency_upper_bound::Frequency
    approximation_lower_bound::Float64
    approximation_upper_bound::Float64
    maximum_error::Float64
    coefficient::Vector{Coefficient} = Coefficient[]
end

"""
    Decimation

Corresponds to SEED blockette 57.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct Decimation
    input_sample_rate::Frequency
    factor::Int
    offset::Int
    delay::Float64
    correction::Float64
end

"""
    ResponseStage

This complex type represents channel response and covers SEED blockettes 53 to 56.

!!! note
    Although the `stage_gain` field is mandatory in the StationXML specification,
    it is common in StationXML files that the field is absent for certain
    types of channel, such as state-of-health channels.  Hence it is an
    optional field of `ResponseStage` in StationXML.jl.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct ResponseStage
    "A choice of response types. There should be one response per stage."
    poles_zeros::M{PolesZeros} = missing
    coefficients::M{Coefficients} = missing
    response_list::M{ResponseList} = missing
    fir::M{FIR} = missing
    polynomial::M{Polynomial} = missing
    decimation::M{Decimation} = missing
    "StageSensitivity is the gain at the stage of the encapsulating
     response element and corresponds to SEED blockette 58. In the SEED
     convention, stage 0 gain represents the overall sensitivity of the channel.
     In this schema, stage 0 gains are allowed but are considered deprecated.
     Overall sensitivity should be specified in the InstrumentSensitivity
     element."
    stage_gain::M{Gain} = missing
    number::Int
    "Same meaning as the `resource_id` field of [`Equipment`](@ref StationXML.Equipment)."
    resource_id::M{String} = missing
    function ResponseStage(poles_zeros, coefficients, response_list, fir, polynomial,
        decimation, stage_gain, number, resource_id)
        count(!ismissing, (poles_zeros, coefficients, response_list, fir, polynomial)) <= 1 ||
            throw(ArgumentError("none or only one response type can be specified"))
        number >= 0 || throw(ArgumentError("number must be 0 or more"))
        new(poles_zeros, coefficients, response_list, fir, polynomial,
            decimation, stage_gain, number, resource_id)
    end
end

attribute_fields(::Type{ResponseStage}) = (:number, :resource_id)

"""
    Response

Instrument sensitivities, or the complete system sensitivity,
can be expressed using either a sensitivity value or a polynomial. The
information can be used to convert raw data to Earth at a specified
frequency or within a range of frequencies.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct Response
    "The total sensitivity for a channel, representing the
     complete acquisition system expressed as a scalar. Equivalent to SEED
     stage 0 gain with (blockette 58) with the ability to specify a frequency
     range."
    instrument_sensitivity::M{Sensitivity} = missing
    "The total sensitivity for a channel, representing the
	complete acquisition system expressed as a
    [`Polynomial`](@ref StationXML.Polynomial). Equivalent to
	SEED stage 0 polynomial (blockette 62). "
    instrument_polynomial::M{Polynomial} = missing
    "Set of [`ResponseStage`](@ref StationXML.ResponseStage)s describing
     each stage in the "
    stage::Vector{ResponseStage} = ResponseStage[]
    resource_id::M{String} = missing
end

attribute_fields(::Type{Response}) = (:resource_id,)

"""
    Operator

An operating agency and associated contact persons. If
there are multiple operators, each one should be encapsulated within an
Operator tag. Since the Contact element is a generic type that
represents any contact person, it also has its own optional `agency`
field.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct Operator
    agency::Vector{String} = String[]
    contact::Vector{Person} = Person[]
    web_site::M{String} = missing
end
