# Types using the base types

@with_kw struct Latitude
    value::Float64
    uncertainty::M{Uncertainty} = missing
    function Latitude(value, uncertainty)
        -90 ≤ value ≤ 90 ||
            throw(ArgumentError("latitude must be in range -90° to 90°"))
        new(latitude, uncertainty)
    end
end

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
