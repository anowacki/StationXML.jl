# Merging of networks and stations

"""
    append!(sxml1, sxml2) -> sxml1

Add all the networks in `sxml2` to `sxml1`, duplicating any networks, stations or
channels that appear in both, even if they are identical.

Note that the `Network`s in the `network` field of `sxml2` will only be
**referred to** in `sxml1`s `network` field.  This means that changes to
`sxml2.network` will also be reflected in `sxml1.network`, even after the
`append!` call.  To avoid this, use `append!(sxml1, deepcopy(sxml2))`.

To return a copy of `sxml1` with the networks of `sxml2` added, whilst leaving
the original `sxml1` unmodified, use `append!(deepcopy(sxml1), sxml2)`.

See also:
[`merge!`](@ref Base.merge!(::StationXML.FDSNStationXML, ::StationXML.FDSNStationXML)),
[`merge`](@ref Base.merge(::StationXML.FDSNStationXML, ::StationXML.FDSNStationXML))
"""
function Base.append!(sxml1::FDSNStationXML, sxml2::FDSNStationXML)
    append!(sxml1.network, sxml2.network)
    sxml1
end

"""
    merge!(sxml1, sxml2[, ...]; warn=true) -> sxml1

Merge two or more [`FDSNStationXML`](@ref) objects into `sxml1`, adding unique
networks, stations and channels so that all are contained in a single object.
Networks are distinguished by their codes; stations and channels are distinguished
by their codes and start and end dates; channels are also distinguished by
their location codes.  Networks, stations and channels which are
duplicated between `sxml1`, `sxml2` (and `sxml3...`) are not duplicated in the
final merged `FDSNStationXML` object.

The implementation always takes the `FDSNStationXML` base information from the first
object.  That is, everything is determined by `sxml1`, apart from the `network` field,
meaning e.g. `source`, `sender`, `created`, etc.

If `warn` is `true` (the default), then warnings are printed when merging
networks or stations with the same code but otherwise different data (e.g.,
channels active at the same time with the same codes, but different azimuths).
If you want to duplicate all networks, stations or channels, use
[`append!`](@ref Base.append!(::StationXML.FDSNStationXML, ::StationXML.FDSNStationXML))
instead.

# Example
Find stations using a web request; `FDSNStationXML` objects are stored in the
stations' `.meta` structure.  We can then merge the station information together.
```
julia> using SeisRequests

julia> stas = get_stations(code="XM.C*..HHZ", starttime="2012-01-01", endtime="2014-01-01")
8-element Vector{Seis.GeogStation{Float64}}:
 Station: XM.C01E..HHZ, lon: 38.385052, lat: 7.22327, dep: 0.0, elev: 1831.0, azi: 0.0, inc: 0.0, meta: 5 keys
 Station: XM.C02E..HHZ, lon: 38.43224, lat: 7.14882, dep: 0.0, elev: 1722.0, azi: 0.0, inc: 0.0, meta: 5 keys
 Station: XM.C03E..HHZ, lon: 38.484409, lat: 7.19804, dep: 0.0, elev: 1759.0, azi: 0.0, inc: 0.0, meta: 5 keys
 Station: XM.C04E..HHZ, lon: 38.476398, lat: 7.21787, dep: 0.0, elev: 1782.0, azi: 0.0, inc: 0.0, meta: 5 keys
 Station: XM.C04E..HHZ, lon: 38.476398, lat: 7.21787, dep: 0.0, elev: 1782.0, azi: 0.0, inc: 0.0, meta: 5 keys
 Station: XM.C05E..HHZ, lon: 38.30228, lat: 7.25978, dep: 0.0, elev: 1946.0, azi: 0.0, inc: 0.0, meta: 5 keys
 Station: XM.C06E..HHZ, lon: 38.372139, lat: 7.13389, dep: 0.0, elev: 1775.0, azi: 0.0, inc: 0.0, meta: 5 keys
 Station: XM.C07E..HHZ, lon: 38.444, lat: 7.26028, dep: 0.0, elev: 1710.0, azi: 0.0, inc: 0.0, meta: 5 keys

julia> sxml = merge(stas.meta.stationxml...) # Merge all separate FDSNStationXML objects
StationXML.FDSNStationXML
  source: String "IRIS-DMC"
  sender: String "IRIS-DMC"
  module_name: String "IRIS WEB SERVICE: fdsnws-station | version: 1.1.47"
  module_uri: String "http://service.iris.edu/fdsnws/station/1/query?starttime=2012-01-01T00:00:00&endtime=2014-01-01T00:00:00&network=XM&station=C*&location=&channel=HHZ&level=channel&nodata=204"
  created: Dates.DateTime
  network: Array{StationXML.Network}((1,))
  schema_version: String "1.1"

julia> channel_codes(sxml) # List of all channel codes in the StationXML
8-element Vector{String}:
 "XM.C01E..HHZ"
 "XM.C02E..HHZ"
 "XM.C03E..HHZ"
 "XM.C04E..HHZ"
 "XM.C04E..HHZ"
 "XM.C05E..HHZ"
 "XM.C06E..HHZ"
 "XM.C07E..HHZ"
```

See also:
[`append!`](@ref Base.append!(::StationXML.FDSNStationXML, ::StationXML.FDSNStationXML))
[`merge`](@ref Base.merge(::StationXML.FDSNStationXML, ::StationXML.FDSNStationXML))
"""
function Base.merge!(sxml1::FDSNStationXML, sxml2::FDSNStationXML; warn=true)
    _merge!(nothing, sxml1, sxml2, warn)
    sxml1
end

function Base.merge!(sxml1::FDSNStationXML, sxml2::FDSNStationXML,
        sxmls::Vararg{FDSNStationXML}; warn=true)
    foldl((x, y) -> merge!(x, y; warn=warn), (sxml1, sxml2, sxmls...))
end

"""
    merge(sxml1, sxml2[, ...]; warn=true) -> sxml

Merge two or more [`FDSNStationXML`](@ref) objects together, adding unique
networks, stations and channels so that all are contained in a single object.

See [`merge!`](@ref Base.merge!(::FDSNStationXML, ::FDSNStationXML)) for
more details of the criteria by which networks, stations and channels
are merged.

See also:
[`append!`](@ref Base.append!(::StationXML.FDSNStationXML, ::StationXML.FDSNStationXML))
"""
Base.merge(sxml1::FDSNStationXML, sxml2::FDSNStationXML; warn=true) =
    merge!(deepcopy(sxml1), sxml2; warn=warn)

function Base.merge(sxml1::FDSNStationXML, sxml2::FDSNStationXML,
        sxmls::Vararg{FDSNStationXML}; warn=true)
    merge!(deepcopy(sxml1), sxml2, sxmls...; warn=warn)
end

_items_for_merging(x::FDSNStationXML, y::FDSNStationXML) = x.network, y.network
_items_for_merging(x::Network, y::Network) = x.station, y.station

"""
Merge two collections `x1` and `x2` together into `x1`.  `x1` is a field of `parent`.
"""
function _merge!(parent, x1, x2, warn)
    y1s, y2s = _items_for_merging(x1, x2)
    # Find network or station codes
    codes1 = (y.code for y in y1s)
    codes2 = (y.code for y in y2s)
    # Items with the same code but which do not overlap in time are
    # considered to be separate (e.g., reusing of temporary network codes;
    # stations which move around in time) and so we don't merge stations or
    # channels.
    # Use `Dict{Int,eltype(y1s)}` rather than `Set{eltype(y1s)}` since this
    # only requires hashing an `Int` rather than a potentially complex type
    # and is therefore be faster.
    different_y2s = Dict{Int,eltype(y1s)}()
    for code in intersect(codes1, codes2)
        # Only iterate over all matching codes to avoid searching through every
        # network/station for both `x1` and `x2`
        i1s = findall(x -> x.code == code, y1s)
        i2s = findall(x -> x.code == code, y2s)
        for i1 in i1s
            y1 = y1s[i1]
            for i2 in i2s
                y2 = y2s[i2]
                # No need to copy identical networks/stations
                if y1 == y2
                    continue
                end
                # Assume that networks/stations with overlapping times are really
                # the same, but with different contents
                if _time_ranges_overlap(y1, y2)
                    _merge!(x1, y1s[i1], y2s[i2], warn)
                else
                    different_y2s[i2] = y2
                end
            end
        end
    end
    append!(y1s, values(different_y2s))

    # Append the items only in x2 to x1
    for code in setdiff(codes2, codes1)
        i2 = findfirst(x -> x.code == code, y2s)
        # deepcopy because the collections contain arrays and it may be unexpected
        # that changing them later in x1 would affect elements of x2
        push!(y1s, deepcopy(y2s[i2]))
    end
    x1
end

"""
Merge two stations together, collecting unique channels into `sta1`.
"""
function _merge!(network::Network, sta1::Station, sta2::Station, warn)
    cha1, cha2 = sta1.channel, sta2.channel
    # Get set of location and channel codes
    codes1 = ((c.code, c.location_code) for c in cha1)
    codes2 = ((c.code, c.location_code) for c in cha2)
    # Channels with the same code but which do not overlap in time are
    # considered to be separate.
    # Use a Dict so we don't need to keep track of whether we have already
    different_c2_channels = Dict{Int,Channel}()
    for (code, loc) in intersect(codes1, codes2)
        i1s = findall(x -> x.code == code && x.location_code == loc, cha1)
        i2s = findall(x -> x.code == code && x.location_code == loc, cha2)
        @assert !(isempty(i1s) || isempty(i2s)) "unexpectedly empty set of channels"
        for i1 in i1s
            c1 = cha1[i1]
            for i2 in i2s
                c2 = cha2[i2]
                # Skip identical channels
                if c1 == c2
                    continue
                end
                # There is a time overlap, so these must be the same channel
                if _time_ranges_overlap(c1, c2)
                    if warn
                        chan_code = join((network.code, sta1.code, loc, code), '.')
                        timerange1 = (c1.start_date, c1.end_date)
                        timerange2 = (c2.start_date, c2.end_date)
                        @warn("""
                            two channels with code '$(chan_code)' overlap in time but are not the same; only keeping the first
                            Time ranges:
                                $(timerange1)
                                $(timerange2)
                            """)
                    end
                # These are different in time, so we need to add c2
                else
                    different_c2_channels[i2] = c2
                end
            end
        end
    end
    append!(cha1, values(different_c2_channels))

    # Append the channels only in cha2 to cha1
    for (code, loc) in setdiff(codes2, codes1)
        i2 = findfirst(x -> x.code == code && x.location_code == loc, cha2)
        push!(cha1, cha2[i2])
    end
    sta1
end

"""
    _time_ranges_overlap(x, y) -> ::Bool

Return `true` if the two networks, stations or channels `x` and `y` overlap
by more than one point in time.

Note that typically the end time of a period of channel operation is the same
as the start time of the next period of operation, hence even when there is no
intended overlap this creates a single point in time where the two ranges
overlap.  Therefore we require two points to overlap in order for a true
overlap to be decided.

Start and end dates are permitted to be `missing` (absent), in which case it
is assumed that a missing start date corresponds to a station always operating
into the past, and that a missing end date corresponds to a station always
operating into the future.  Hence two stations which both have missing end
dates but set start dates are assumed to overlap, and similarly for a pair
with different end dates but both with missing start dates
"""
function _time_ranges_overlap(x, y)
    b1, e1 = x.start_date, x.end_date
    b2, e2 = y.start_date, y.end_date
    nmissings = count(x -> x === missing, (b1, e1, b2, e2))

    # If all missing or only one non-missing, assume overlap
    if nmissings in (3, 4)
        return true
    elseif nmissings == 2
        # One station has no date information; assume overlap
        if (b1 === missing && e1 === missing) || (b2 === missing && e2 === missing)
            return true
        # Pairs of start or end times are missing; assume overlap
        elseif (b1 === missing && b2 === missing) || (e1 === missing && e2 === missing)
            return true
        # 'Cross terms' are missing, so only need to check one pair
        elseif (b1 === missing && e2 === missing && b2 >= e1) ||
                (b2 === missing && e1 === missing && b1 >= e2)
            return false
        # We have 'cross terms' but there is an overlap
        else
            return true
        end
    # Just convert the single missing value to something we can work with then
    elseif nmissings === 1
        b1 === missing && (b1 = typemin(b2))
        b2 === missing && (b2 = typemin(b1))
        e1 === missing && (e1 = typemax(e2))
        e2 === missing && (e2 = typemax(e1))
    end

    # No missing values now
    # x before y and no overlap
    if e1 <= b2
        return false
    # y before x and no overlap
    elseif e2 <= b1
        return false
    else
        return true
    end
end
