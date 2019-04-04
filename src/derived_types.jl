# Types using the base types

"Complex type for sensitivity and frequency ranges. This complex type
can be used to represent both overall sensitivities and individual stage gains. The
FrequencyRangeGroup is an optional construct that defines a pass band in Hertz
(FrequencyStart and FrequencyEnd) in which the SensitivityValue is valid within the
number of decibels specified in FrequencyDBVariation. "
@with_kw struct Gain
    "A scalar that, when applied to the data values, converts the data to different units (e.g. Earth units)"
    value::Float64
    "The frequency (in Hertz) at which the Value is valid."
    frequency::Float64
end

"""Sensitivity and frequency ranges. The FrequencyRangeGroup is an
optional construct that defines a pass band in Hertz (FrequencyStart and
FrequencyEnd) in which the SensitivityValue is valid within the number of decibels
specified in FrequencyDBVariation. """
@with_kw struct Sensitivity
    "The units of the data as input from the perspective
	 of data acquisition. After correcting data for this response, these
	 would be the resulting units."
    input_units::Units
    "The units of the data as output from the perspective
	 of data acquisition. These would be the units of the data prior to
	 correcting for this response."
    output_units::Units
    "The frequency range for which the SensitivityValue is
	 valid within the dB variation specified."
    frequency_range::M{FrequencyRange} = missing
end

"Sensor equipment installed at a Station"
@with_kw struct Equipment
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

"""Response: complex poles and zeros. Corresponds to SEED blockette 53."""
@with_kw struct PolesZeros
    @BaseFilter
    pz_transfer_function_type::String
    normalization_factor::Float64 = 1.0
    normalization_frequency::Float64
    zero::Vector{PoleZero} = PoleZero[]
    pole::Vector{PoleZero} = PoleZero[]
end

@with_kw struct NumeratorCoefficient
    value::Float64
    i::Int
end

"""Response: FIR filter. Corresponds to SEED blockette 61. FIR filters
are also commonly documented using the CoefficientsType element."""
@with_kw struct FIR
    @BaseFilter
    symmetry::String
    numerator_coefficient::Vector{NumeratorCoefficient} = NumeratorCoefficient[]
end

"""Response: coefficients for FIR filter. Laplace transforms or IIR
filters can be expressed using type as well but the PolesAndZerosType should be used
instead. Corresponds to SEED blockette 54."""
@with_kw struct Coefficients
    @BaseFilter
    cf_transfer_function_type::String
    numerator::Vector{Float64} = Float64[]
    denominator::Vector{Float64} = Float64[]
end

@with_kw struct ReponseListElement
    frequency::Float64
    amplitude::Float64
    phase::Float64
end

"""Response: list of frequency, amplitude and phase values. Corresponds to SEED blockette 55. """
@with_kw struct ResponseList
    @BaseFilter
    response_list_element::Vector{ReponseListElement} = ReponseListElement[]
end

@with_kw struct Coefficient
    value::Float64
    number::Int
end

"""Response: expressed as a polynomial (allows non-linear sensors to be
described). Corresponds to SEED blockette 62. Can be used to describe a stage of
acquisition or a complete system."""
@with_kw struct Polynomial
    @BaseFilter
    approximation_type::String = "MACLAURIN"
    frequency_lower_bound::Float64
    frequency_upper_bound::Float64
    approximation_lower_bound::Float64
    approximation_upper_bound::Float64
    maximum_error::Float64
    coefficient::Vector{Coefficient} = Coefficient[]
end

"""Corresponds to SEED blockette 57."""
@with_kw struct Decimation
    input_sample_rate::Float64
    factor::Int
    offset::Int
    delay::Float64
    correction::Float64
end

"""This complex type represents channel response and covers SEED blockettes 53 to 56."""
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
    resource_id::M{String} = missing
    function ResponseStage(poles_zeros, coefficients, response_list, fir, polynomial,
        decimation, stage_gain, number, resource_id)
        count(!ismissing, (poles_zeros, coefficients, response_list, fir, polynomial)) == 1 ||
            throw(ArgumentError("One and only one response type should be specified"))
        new(poles_zeros, coefficients, response_list, fir, polynomial,
            decimation, stage_gain, number, resource_id)
    end
end

"""Instrument sensitivities, or the complete system sensitivity,
can be expressed using either a sensitivity value or a polynomial. The
information can be used to convert raw data to Earth at a specified
frequency or within a range of frequencies. """
@with_kw struct Response
    "The total sensitivity for a channel, representing the
     complete acquisition system expressed as a scalar. Equivalent to SEED
     stage 0 gain with (blockette 58) with the ability to specify a frequency
     range. "
    instrument_sensitivity::M{Sensitivity} = missing
    "The total sensitivity for a channel, representing the
	complete acquisition system expressed as a polynomial. Equivalent to
	SEED stage 0 polynomial (blockette 62). "
    instrument_polynomial::M{Polynomial} = missing
    stage::Vector{ResponseStage} = ResponseStage[]
    resource_id::M{String} = missing
end

"An operating agency and associated contact persons. If
there multiple operators, each one should be encapsulated within an
Operator tag. Since the Contact element is a generic type that
represents any contact person, it also has its own optional Agency
element."
@with_kw struct Operator
    agency::Vector{String} = String[]
    contact::Vector{Person} = Person[]
    web_site::M{String} = missing
end
