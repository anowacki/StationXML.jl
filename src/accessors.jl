# Functions to access fields nested within higher-level types

"""
    networks(stationxml) -> ::Vector{Network}

Return the networks contained within a `FDSNStationXML` object.
"""
networks(sxml::FDSNStationXML) = sxml.network

"""
    stations(stationxml) -> ::Vector{Station}
    stations(network) -> ::Vector{Station}

Return a flattened list of all stations within the entire FDSNStationXML object, or within
a `network`.
"""
stations(sxml::FDSNStationXML) = collect(Iterators.flatten(stations(net) for net in sxml.network))
stations(net::Network) = net.station

"""
    channels(stationxml) -> ::Vector{Channel}
    channels(network) -> ::Vector{Channel}
    channels(station) -> ::Vector{Channel}

Return a flattened list of channels contained within a FDSNStationXML object, a whole
`network`, or a single `station`.
"""
channels(sxml::FDSNStationXML) = collect(Iterators.flatten(channels(net) for net in sxml.network))
channels(net::Network) = collect(Iterators.flatten(channels(sta) for sta in net.station))
channels(sta::Station) = sta.channel

# Julia v1.11 breaks the old way of using `getproperty` and we must
# do this to keep it working; see https://github.com/JuliaLang/julia/issues/56100
#
# TODO: Remove this in next version bump because it is type-piracy.
for T in (Network, Station, Channel)
    for A in (AbstractArray, Array)
        @eval function Base.getproperty(x::$A{$T}, f::Symbol)
            if f in fieldnames(typeof(x))
                getfield(x, f)
            else
                getproperty.(x, f)
            end
        end
    end
end

"""
    channel_codes(network) -> ::Vector{String}
    channel_codes(stationxml) -> ::Vector{String}

Return a list of the channel codes of all the channels within
a `network` or `stationxml` document.
"""
function channel_codes(network::Network)
    cha_codes = String[]
    net = network.code
    for station in stations(network)
        sta = station.code
        for channel in channels(station)
            cha = channel.code
            loc = coalesce(channel.location_code, "")
            push!(cha_codes, "$net.$sta.$loc.$cha")
        end
    end
    cha_codes
end

channel_codes(sxml::FDSNStationXML) = reduce(vcat, channel_codes.(networks(sxml)))
