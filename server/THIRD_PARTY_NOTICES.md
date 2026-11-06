# Third-party notices (server)

The server is built with open-source Go modules, listed with their licences in `go.mod`. These need a notice of their own:

## Time zones by place

The time zone of an imported photo is worked out from where it was taken with [tzf](https://github.com/ringsaturn/tzf) (MIT) and [orb](https://github.com/ringsaturn/orb) (MIT).

Their time zone boundaries come from [tzf-dist](https://github.com/ringsaturn/tzf-dist) (code MIT), built from [timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder), which is made available under the [Open Database License (ODbL) 1.0](https://opendatacommons.org/licenses/odbl/1-0/). The data contains information from [OpenStreetMap](https://www.openstreetmap.org/copyright), © OpenStreetMap contributors.

## Keeping other servers' backups

The backups a server keeps for other Mediarr servers are served with the `repo` package of [rest-server](https://github.com/restic/rest-server), Copyright © 2015, Bertil Chapuis, under the BSD 2-Clause License. Backups are made with [restic](https://restic.net) (BSD 2-Clause), installed in the image.
