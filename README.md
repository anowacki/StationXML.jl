# StationXML

Read and write [FDSN StationXML-format](https://www.fdsn.org/xml/station)
files describing seismic stations.

[![Build Status](https://travis-ci.org/anowacki/StationXML.jl.svg?branch=master)](https://travis-ci.org/anowacki/StationXML.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/qjedw1iel0d4vhh4?svg=true)](https://ci.appveyor.com/project/AndyNowacki/stationxml-jl)
[![Coverage Status](https://coveralls.io/repos/github/anowacki/StationXML.jl/badge.svg?branch=master)](https://coveralls.io/github/anowacki/StationXML.jl?branch=master)

The package follows the [FDSN schema](https://www.fdsn.org/xml/station/fdsn-station-1.1.xsd).

## Installation

```julia
import Pkg; Pkg.pkg"add https://github.com/anowacki/StationXML.jl"
```


## Use

`StationXML` is mainly designed to be used by other modules such
as [Seis](https://github.com/anowacki/Seis.jl) to process
station information.  Therefore, relatively few convenience functions
are defined for working with `FDSNStationXML` objects.  However,
the package aims to comprehensively document all objects and functions
used.

The basic type exported by StationXML.jl is `FDSNStationXML`.


### Reading FDSN StationXML data

Two unexported functions are available for use in creating `FDSNStationXML` objects:

- `StationXML.read(filename)`: Read from a file on disk.
- `StationXML.readstring(string)`: Parse from a `String`.

For instance (using an example StationXML file supplied with this module):

```julia
julia> using StationXML

julia> sxml = StationXML.read(joinpath(dirname(pathof(StationXML)), "..", "test", data", "JSA.xml"))
StationXML.FDSNStationXML
  source: String "IRIS-DMC"
  sender: String "IRIS-DMC"
  module_name: String "IRIS WEB SERVICE: fdsnws-station | version: 1.1.36"
  module_uri: String "http://service.iris.edu/fdsnws/station/1/query?network=GB&station=JSA&level=response&format=xml&nodata=204"
  created: Dates.DateTime
  network: Array{StationXML.Network}((1,))
  schema_version: String "1.0"

```

### Writing data

Simply call `write` on an `FDSNStationXML` object to write it to disk or other
`IO` stream:

```julia
julia> write("output_file.xml", sxml)
```

StationXML.jl **always** writes files according to the v1.1 schema.

Note that v1.1 removed a small number of fields from the specification.  Therefore, if
you are writing an `FDSNStationXML` object read from a v1.0 file, there is the potential
that information may be lost.  If you are worried, pass the `warn=true` keyword argument
to `write` to enable warnings for the presence of any fields which will not be written.

### Accessing fields

You should access the fields of `FDSNStationXML` objects directly.  These match the
StationXML specification directly, and are listed in each type's docstrings.
These are accessible via the REPL by typing `?` and then the name of the
type.  For example:

```julia
julia> ? # REPL prompt becomes help?>
help> StationXML.Channel
  Channel

  A channel is a time series recording of a component of some observable, often
  colocated with other channels at the same location of a station.

  Equivalent to SEED blockette 52 and parent element for the related the response
  blockettes.

  │ Note
  │
  │  The presence of a sample_rate_ratio without a sample_rate field is not
  │  allowed in the standard, but it permitted by StationXML.jl.

  List of fields
  ≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡

    •    description::Union{Missing, String}
      
        Default: missing
...
```

To find out how many stations are in each of the networks returned in your request
XML, and what the network code is, you can do:

```julia
julia> for net in sxml.network
           println(net.code, ": ", net.total_number_stations, " stations")
       end
BG: 29 stations
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
package to get all the broadband, high-gain channels stations in the GB network from 2012 to now:

```julia
julia> using StationXML, SeisRequests, Dates

julia> sxml = get_request(
                 FDSNStation(starttime=DateTime(2012), network="GB",
                             location="--", channel="BH?",
                             level="channel")).body |> String |>
                 StationXML.readstring;

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


### Accessor functions

You can easily construct vectors of all the networks, stations and channels in the StationXML
using the following accessor functions:

- `networks(stationxml)`
- `stations(stationxml_or_network)`
- `channels(stationxml_or_network_or_station)`

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


### Dot-access to arrays of objects

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
 StationXML.Longitude(-3.9087, missing, missing, missing, "WGS84")
 StationXML.Longitude(-3.9087, missing, missing, missing, "WGS84")
 StationXML.Longitude(-3.9087, missing, missing, missing, "WGS84")
 StationXML.Longitude(-5.227299, missing, missing, missing, "WGS84")
 StationXML.Longitude(-5.227299, missing, missing, missing, "WGS84")
 StationXML.Longitude(-5.227299, missing, missing, missing, "WGS84")
 StationXML.Longitude(-6.110599, missing, missing, missing, "WGS84")
 StationXML.Longitude(-6.110599, missing, missing, missing, "WGS84")
 StationXML.Longitude(-6.110599, missing, missing, missing, "WGS84")
 ⋮
```


### Structure of objects

`StationXML` represents the XML as laid out in the StationXML schema.
Therefore, it contains all the information in a StationXML file which
is part of the StationXML standard.  Elements and attributes of the XML
are fields within structures nested several layers deep.


## Contributing

### Bugs and omissions
StationXML.jl should read any schema-compatible StationXML
file without error, therefore any examples of documents failing are very
warmly welcomed as are all bug reports.

Please [open an issue](https://github.com/anowacki/StationXML.jl/issues/new)
with a link to the document which is causing problems and as much
information as possible about how to reproduce your error.

### Features
If you would like to add a feature to StationXML, this will be seriously
considered.  The package aims to be fairly minimal so please think very
carefully before adding large dependencies.

New code for the repo should come via a pull request.
