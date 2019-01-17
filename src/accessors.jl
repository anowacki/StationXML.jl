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

Base.getproperty(net::AbstractArray{Network}, f::Symbol) = getfield.(net, f)
Base.getproperty(sta::AbstractArray{Station}, f::Symbol) = getfield.(sta, f)
Base.getproperty(cha::AbstractArray{Channel}, f::Symbol) = getfield.(cha, f)

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
