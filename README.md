# FlightGearBuilder-NG
Next Generation of FlightGearBuilder

It replaces:
- [FlightGearBuilder](https://github.com/Megaf/FlightGearBuilder)
- [FlightGear-Installer](https://github.com/Megaf/FlightGear-Installer)
- [CompileFlightGearDebian](https://github.com/Megaf/CompileFlightGearDebian)

## About
**FlightGearBuilder-NG** Is a Shell Script that is used to build the **[FlightGear Flight Simulator](https://www.flightgear.org/)** from it's source code.

It will download, confgure and compile FlightGear and its main dependencies.
- [Plib](https://sourceforge.net/projects/libplib/)
- [OpenSceneGraph](https://github.com/openscenegraph/OpenSceneGraph.git)
- [SimGear](https://sourceforge.net/p/flightgear/simgear/ci/next/tree/)
- [FlightGear](https://sourceforge.net/p/flightgear/flightgear/ci/next/tree/)

## Using it
Running FlightGearBuilder-NG
```bash
./FlightGearBuilder-NG
```

# ATTENTION
- By default it will download and install FlightGear to a volume called **FlightGear** in the directory `/media/$USER/`. So it installs to `/media/$USER/FlightGear`

### Installing FlightGear with this script.
You need to specify which "component" you want the script to build and install.

The following options are available:

- `--install-plib`: Installs Plib
- `--install-osg`: Installs OpenSceneGraph
- `--install-simgear`: Install SimGear
- `--install-flightgear`: Installs FlightGear

FlightGear depends on SimGear, OSG and Plib.

SimGear depends on OSG.

*You can specify them in any order and the script will figure out the right install order for you.*

#### Example:

```bash
cd FlightGearBuilder-NG
./FlightGearBuilder-NG --install-osg --install-flightgear --install-plib --install-simgear
```
You can also tell the script to not download, run cmake, compile or install your component selection.

- `--no-download`: Will not download/update the source code before trying to compile it.
- `--no-cmake`: Will not run `cmake`, jumping straight to compiling.
- `--no-compile`: Will not run `make`.
- `--no-install`: Will not run `make install`.

The script should be clever enough to find the main software to build FlightGear, things like `gcc`, `cmake`, `git` and so on.

Specific dependencies will be pointed out by each component's own cmake however.

By the way, there's no `--help` yet. Try it.
