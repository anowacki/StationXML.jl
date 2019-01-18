# StationXML

Read FDSN StationXML-format files describing seismic stations.

[![Build Status](https://travis-ci.org/anowacki/StationXML.jl.svg?branch=master)](https://travis-ci.org/anowacki/StationXML.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/qjedw1iel0d4vhh4?svg=true)](https://ci.appveyor.com/project/AndyNowacki/stationxml-jl)

The package mostly follows the [FDSN schema](https://www.fdsn.org/xml/station/fdsn-station-1.0.xsd), with some variation.  It should read any
schema-compatible StationXML file without error, but bug reports
are welcome.

## Installation

```julia
import Pkg; Pkg.pkg"add https://github.com/anowacki/StationXML.jl"
```


## Use

`StationXML` is mainly designed to be used by other modules such
as [Seis](https://github.com/anowacki/Seis.jl) to process
station information.


### Reading files

Say you have a file `xml_file` which contains information about
a selection of stations within a set of networks in FDSN StationXML
format.  Read this in with:

```julia
julia> using StationXML

julia> sxml = StationXML.read(xml_file)
FDSNStationXML
  source: String "IRIS-DMC"
  sender: String "IRIS-DMC"
  module_name: String "IRIS WEB SERVICE: fdsnws-station | version: 1.1.36"
  module_uri: String "http://service.iris.edu/fdsnws/station/1/query?network=GB&station=JSA&level=response&format=xml&nodata=204"
  created: Dates.DateTime
  network: Array{StationXML.Network}((1,))
  schema_version: String "1.0"
```

By default, the REPL will show you all the fields and their types or
content, and so we can see this request has returned one network.  This
can be accessed in a couple of ways, either by accessing the fields
of the object, or with the `networks` helper function:

```julia
julia> sxml.network[1]
StationXML.Network
  description: String "Great Britain Seismograph Network"
  comment: Array{StationXML.Comment}((0,))
  code: String "GB"
  start_date: Dates.DateTime
  end_date: Dates.DateTime
  restricted_status: StationXML.RestrictedStatus
  alternate_code: Missing missing
  historical_code: Missing missing
  total_number_stations: Int64 29
  selected_number_stations: Int64 1
  station: Array{StationXML.Station}((1,))


julia> sxml.network == networks(sxml)
true
```


### Reading strings

The `StationXML.readstring` function will read a `String` in memory
into a `StationXML.FDSNStationXML` object.  This is useful if
requesting such information via the [SeisRequests](https://github.com/anowacki/SeisRequests.jl) module.


## Structure of objects

`StationXML` represents the XML as laid out in the StationXML schema.
Therefore, it aims to contain almost all the information which can
be contained in a StationXML file.  Elements and attributes of the XML
are fields within structures nested several layers deep.
