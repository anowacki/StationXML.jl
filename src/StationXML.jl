"""
# StationXML

Implement the FDSN StationXML specification to describe seismic (and other)
stations recording regularly-sampled information such as ground velocity.

Full specification can be found at:

    https://www.fdsn.org/xml/station/fdsn-station-1.0.xsd


## Reading FDSN StationXML data

Two unexported functions are available for use in creating `FDSNStationXML` objects:

- `StationXML.read(filename)`: Read from a file on disk.
- `StationXML.readstring(string)`: Parse from a `String`.

For instance (using an example StationXML file supplied with this module):

```julia
julia> using StationXML

julia> sxml = StationXML.read(joinpath(dirname(pathof(StationXML)), "..", "data", "JSA.xml"))
StationXML.FDSNStationXML
  source: String "IRIS-DMC"
  sender: String "IRIS-DMC"
  module_name: String "IRIS WEB SERVICE: fdsnws-station | version: 1.1.36"
  module_uri: String "http://service.iris.edu/fdsnws/station/1/query?network=GB&station=JSA&level=response&format=xml&nodata=204"
  created: Dates.DateTime
  network: Array{StationXML.Network}((1,))
  schema_version: String "1.0"

```

## Accessing fields

You should access the fields of `FDSNStationXML` objects directly.  These match the
StationXML specification directly, and can also be listed for each of the types with
the usual `fieldnames(::DataType)` function.  (E.g., `fieldnames(Channel)`.)

To find out how many stations are in each of the networks returned in your request
XML, and what the network code is, you can do:

```julia
julia> for net in sxml.network
           println(net.code, ": ", net.total_number_stations, " stations")
       end
29
```

To get a vector of the station codes in the one network (GB) returned in our request:

```julia
julia> gb = sxml.network[1];

julia> stas = [sta.code for sta in gb.station]
1-element Array{String,1}:
 "JSA"

```

You can also access individual networks, stations and channels using functions with
these names.  For example, using the [SeisRequests](https://github.com/anowacki/SeisRequests.jl)
package to get all the broadband, high-gain channels stations in the GB network:

```julia
julia> using SeisRequests, Dates

julia> xml = get_request(
                 FDSNStation(starttime=DateTime(2012), endtime=now(), network="GB",
                             station="*", location="--", channel="BH?",
                             level="channel")).body |> String;

julia> [s.code for s in stations(sxml)]
28-element Array{String,1}:
 "BIGH"
 "CCA1"
 "CLGH"
 "CWF"
 "DRUM"
 "DYA"
 "EDI"
 "EDMD"
 "ELSH"
 "ESK"
 "FOEL"
 "GAL1"
 "HMNX"
 "HPK"
 "HTL"
 "IOMK"
 "JSA"
 "KESW"
 "KPL"
 "LBWR"
 "LMK"
 "LRW"
 "MCH1"
 "SOFL"
 "STNC"
 "SWN1"
 "WACR"
 "WLF1"

```


## Accessor functions

You can easily construct vectors of all the networks, stations and channels in the StationXML
using the following accessor functions:

- networks(stationxml)
- stations(stationxml_or_network)
- channels(stationxml_or_network_or_station)

Note that `station`, for instance, accepts either a `Network` or a whole `FDSNStationXML`
object, whilst either of those or a `Station` can be given to `channels`.

```julia
julia> stations(gb)
28-element Array{StationXML.Station,1}:
 StationXML.Station(missing, StationXML.Comment[], "BIGH", 2009-12-15T00:00:00, 2599-12-31T23:59:59, StationXML.RestrictedStatus
  value: String "open"
...
```

The `channel_codes` function returns a list of all of the channel codes within
a `FDSNStationXML` document or a `Network`.

## Dot-access to arrays of objects

The module defines `getproperty` methods for conveniently accessing the fields of each member
of arrays of `Network`s, `Station`s and `Channel`s.  So our previous example of finding all
the station codes could actually have been done like this:

```julia
julia> stations(sxml).code
28-element Array{String,1}:
 "BIGH"
 "CCA1"
 "CLGH"
 "CWF"
...
```

We can equally access any other field of the items this way:

```julia
julia> channels(sxml).longitude
84-element Array{Float64,1}:
 -3.9087
 -3.9087
 -3.9087
 -5.227299
 -5.227299
 -5.227299
 -6.110599
 -6.110599
 -6.110599
...
```


## Preamble to the specification

#### FDSN StationXML (www.fdsn.org/xml/station)

The purpose of this schema is to define an XML representation of the most important
and commonly used structures of SEED 2.4 metadata.

The goal is to allow mapping between SEED 2.4 dataless SEED volumes and this schema with as
little transformation or loss of information as possible while at the same time simplifying
station metadata representation when possible.  Also, content and clarification has been added
where lacking in the SEED standard.

When definitions and usage are underdefined the SEED manual should be referred to for
clarification.  SEED specifiation: http://www.fdsn.org/publications.htm

Another goal is to create a base schema that can be extended to represent similar data types.


#### Versioning for FDSN StationXML:

The `version` attribute of the schema definition identifies the version of the schema.  This
version is not enforced when validating documents.

The required `schemaVersion` attribute of the root element identifies the version of the schema
that the document is compatible with.  Validation only requires that a value is present but
not that it matches the schema used for validation.

The `targetNamespace` of the document identifies the major version of the schema and document,
version 1.x of the schema uses a target namespace of "http://www.fdsn.org/xml/station/1".
All minor versions of a will be backwards compatible with previous minor releases.  For
example, all 1.x schemas are backwards compatible with and will validate documents for 1.0.
Major changes to the schema that would break backwards compabibility will increment the major
version number, e.g. 2.0, and the namespace, e.g. "http://www.fdsn.org/xml/station/2".

This combination of attributes and `targetNamespace`s allows the schema and documents to be
versioned and allows the schema to be updated with backward compatible changes (e.g. 1.2)
and still validate documents created for previous major versions of the schema (e.g. 1.0).

"""
module StationXML

using Dates

using Mixers: @pour
using Parameters: @with_kw
import EzXML
import DocStringExtensions

export
  FDSNStationXML,
  channel_codes,
  channels,
  networks,
  stations,
  xmldoc

const M{T} = Union{T,Missing}

include("compat.jl")
include("util.jl")
include("base_types.jl")
include("derived_types.jl")
include("types.jl")
include("deprecations.jl")
include("accessors.jl")
include("io.jl")

include("precompile.jl")

end # module
