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
    "A scalar that, when applied to the data values, converts the data to different units (e.g. Earth units).
     Although this must be present according to the specification, it can be
     `missing` here."
    value::M{Float64} = missing
    "The frequency (in Hertz) at which the `value` is valid.
     Although this must be present according to the specification, it can be
     `missing` here."
    frequency::M{Float64} = missing
    "The units of the data as input from the perspective
	 of data acquisition. After correcting data for this response, these
	 would be the resulting units.  (Mandatory in the StationXML specification,
     but optional here since some older channels did not specify input units,
     for example when a channel records state-of-health information or
     other metadata.)"
    input_units::M{Units} = missing
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
    The `Log` type is no longer present in StationXML v1.1 and later.
    It is included here for compatibility with v1.0 files.

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
@with_kw struct NumeratorCoefficient <: NumberType
    value::Float64
    i::M{Int} = missing
    NumeratorCoefficient(value, i=missing) = new(value, i)
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
are also commonly documented using the `Coefficients` type.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw mutable struct FIR
    @BaseFilter
    "Symmetry of filter.  Must be one of `\"NONE\"`, `\"EVEN\"` or `\"ODD\"`.
     See [`StationXML.FIR`](@ref)."
    symmetry::FIRSymmetry
    "Set of [`NumeratorCoefficient`](@ref StationXML.NumeratorCoefficient)s."
    numerator_coefficient::Vector{NumeratorCoefficient} = NumeratorCoefficient[]
end

attribute_fields(::Type{FIR}) = BASE_FILTER_ATTRIBUTES

@enumerated_struct(CfTransferFunction,
    ("ANALOG (RADIANS/SECOND)", "ANALOG (HERTZ)", "DIGITAL"))

"""
    Coefficient

Extension of [`FloatNoUnit`](@ref StationXML.FloatNoUnit) with an
additional `number` attribute, used as the `numerator` and `denominator`
of [`Coefficients`](@ref StationXML.Coefficients) and
[`Polynomial`](@ref StationXML.Polynomial).

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct Coefficient <: NumberType
    "Value of the coefficient (no unit)"
    value::Float64
    "Absolute error in the positive direction."
    plus_error::M{Float64} = missing
    "Absolute error in the negative direction (i.e., this value should be positive)."
    minus_error::M{Float64} = missing
    "Method used to make measurement"
    measurement_method::M{String} = missing
    "Number of the coefficient"
    number::M{Int} = missing

    function Coefficient(value, plus_error=missing, minus_error=missing,
            measurement_method=missing, number=missing)
        number !== missing && number < 0 &&
            throw(ArgumentError("number must be 0 or greater"))
        new(value, plus_error, minus_error, measurement_method, number)
    end
end

attribute_fields(::Type{Coefficient}) = (:plus_error, :minus_error,
    :measurement_method, :number)

function parse_node(::Type{Coefficient}, node::EzXML.Node, warn::Bool=false)
    value = parse(Float64, node.content)
    plus_error = minus_error = measurement_method = number = missing
    for att in EzXML.eachattribute(node)
        name = att.name
        if name == "number"
            number = parse(Int, att.content)
        elseif name == "plusError"
            plus_error = parse(Float64, att.content)
        elseif name == "minusError"
            minus_error = parse(Float64, att.content)
        elseif name == "measurementMethod"
            measurement_method = att.content
        else
            warn && @warn("unexpected attribute $(att.name) for NumeratorCoefficient")
        end
    end
    Coefficient(value, plus_error, minus_error, measurement_method, number)
end

const Numerator = Coefficient
const Denominator = Coefficient

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
    "Type of the transfer function (see [`CfTransferFunction`](@ref)."
    cf_transfer_function_type::CfTransferFunction
    numerator::Vector{Numerator} = Numerator[]
    denominator::Vector{Denominator} = Denominator[]
end

attribute_fields(::Type{Coefficients}) = BASE_FILTER_ATTRIBUTES

"""
    ResponseListElement(frequency, amplitude, phase)

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct ResponseListElement
    "Frequency at which the `amplitude` and `phase` was measured."
    frequency::Frequency
    "Amplitude response at the given `frequency`."
    amplitude::Float
    "Phase angle response at the given `frequency`"
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
    "Set of [`ResponseListElement`](@ref)s."
    response_list_element::Vector{ResponseListElement} = ResponseListElement[]
end

attribute_fields(::Type{ResponseList}) = BASE_FILTER_ATTRIBUTES

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
    "The low frequency corner for which the sensor is valid."
    approximation_lower_bound::Float64
    "The high frequency corner for which the sensor is valid."
    approximation_upper_bound::Float64
    maximum_error::Float64
    coefficient::Vector{Coefficient} = Coefficient[]
end

"""
    Decimation

Description of the decimation stage of a response.

Corresponds to SEED blockette 57.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct Decimation
    "Sample rate of the signal before decimation."
    input_sample_rate::Frequency
    "Number of times the signal is decimated.  The output sample rate
     is therefore `input_sample_rate ÷ factor`."
    factor::Int
    "Which sample is chosen for use when decimating, starting at 0 for
     the first sample in the window of `factor` samples.
     (This implies `0 <= offset < factor`.)"
    offset::Int
    "The estimated pure delay of the signal, where positive values
     mean a time delay or shift to later in time."
    delay::Float64
    "Time shift applied to correct for the delay introduced in this
     stage.  Positive numbers mean a time advance or shift to earlier in time."
    correction::Float64
end

"""
    ResponseStage

Represents a channel's response and covers SEED blockettes 53 to 56.

!!! note
    Although the `stage_gain` field is mandatory in v1.0 of the StationXML specification,
    it is common in StationXML files that the field is absent for certain
    types of channel, such as state-of-health channels.  Hence it is an
    optional field of `ResponseStage` in StationXML.jl.
    Version 1.1 of the specification removed the requirement for a `stage_gain`
    when a `polynomial` stage is defined, rather than one of `poles_zeros`,
    `coefficients`, `response_list` or `fir`.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct ResponseStage
    "A choice of `polynomial` versus all other response types.
     There should be one response per stage."
    poles_zeros::M{PolesZeros} = missing
    coefficients::M{Coefficients} = missing
    response_list::M{ResponseList} = missing
    fir::M{FIR} = missing
    polynomial::M{Polynomial} = missing
    decimation::M{Decimation} = missing
    "The gain at the stage of the encapsulating
     response element and corresponds to SEED blockette 58. In the SEED
     convention, stage 0 gain represents the overall sensitivity of the channel.
     In this schema, stage 0 gains are allowed but are considered deprecated.
     Overall sensitivity should be specified in the InstrumentSensitivity
     element."
    stage_gain::M{Gain} = missing
    "Stage sequence number. This is used in all the response SEED blockettes."
    number::Int
    "Same meaning as the `resource_id` field of [`Equipment`](@ref StationXML.Equipment)."
    resource_id::M{String} = missing
    function ResponseStage(poles_zeros, coefficients, response_list, fir, polynomial,
        decimation, stage_gain, number, resource_id)
        count(!ismissing, (poles_zeros, coefficients, response_list, fir, polynomial)) <= 1 ||
            throw(ArgumentError("none or only one response type can be specified"))
        number >= 0 || throw(ArgumentError("number must be 0 or more"))
        polynomial !== missing && stage_gain !== missing &&
            @warn("stage_gain cannot be specified for polynomial stages in StationXML v1.1")
        new(poles_zeros, coefficients, response_list, fir, polynomial,
            decimation, stage_gain, number, resource_id)
    end
end

attribute_fields(::Type{ResponseStage}) = (:number, :resource_id)

"""
    Response

Instrument sensitivities, or the complete system sensitivity,
can be expressed using either a sensitivity value or a polynomial. The
information can be used to convert raw data to real units at a specified
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
field.  It is expected that typically the contact’s optional `agency`
field will match the `Operator` `agency`. Only contacts appropriate for the
enclosing element should be included in the `Operator` object.

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct Operator
    "Only one agency is allowed in StationXML v1.1."
    agency::Vector{String} = String[]
    contact::Vector{Person} = Person[]
    web_site::M{String} = missing
end

"""
    DataAvailability

A description of time series data availability. This information should be
considered transient and is primarily useful as a guide for generating time
series data requests. The information for a DataAvailability:Span may be
specific to the time range used in a request that resulted in the document
or limited to the availability of data withing the request range. These details
may or may not be retained when synchronizing metadata between data centers. 

# List of fields
$(DocStringExtensions.TYPEDFIELDS)
"""
@with_kw struct DataAvailability
    extent::M{DataAvailabilityExtent} = missing
    span::Vector{DataAvailabilitySpan} = DataAvailabilitySpan[]
end
