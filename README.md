# FlightGearBuilder-NG
Next Generation of FlightGearBuilder, by Megaf

![image](https://github.com/Megaf/FlightGearBuilder-NG/assets/6201512/0e1906ce-1889-45ef-a920-4c7af8e261b2)


### It replaces:
- [FlightGearBuilder](https://github.com/Megaf/FlightGearBuilder)
- [FlightGear-Installer](https://github.com/Megaf/FlightGear-Installer)
- [CompileFlightGearDebian](https://github.com/Megaf/CompileFlightGearDebian)

## About
**FlightGearBuilder-NG** Is a Shell Script that is used to build the **[FlightGear Flight Simulator](https://www.flightgear.org/)** from it's source code.

It will download, configure and compile FlightGear and its main dependencies.
- [Plib](https://sourceforge.net/projects/libplib/)
- [OpenSceneGraph](https://github.com/openscenegraph/OpenSceneGraph)
- [osgXR](https://github.com/amalon/osgXR)
- [SimGear](https://sourceforge.net/p/flightgear/simgear/ci/next/tree/)
- [FlightGear](https://sourceforge.net/p/flightgear/flightgear/ci/next/tree/)

## Using it
Running FlightGearBuilder-NG
```bash
./FlightGearBuilder-NG --install-plib --install-osg \
--install-simgear --install-flightgear
```

# ATTENTION
- By default, FlightGear will be installed to `/home/$USER/FlightGear`.
- You can change the install location with the `--install-dir="/path"` flag.
- DO NOT run two instances of the script at the same time!
- DO NOT run two instances of two difference versions of FlightGear!
- FlightGear Stable and FlightGear Next will share FGData, Aircraft, Scenery and Downloads.

### Installing FlightGear with this script.
You need to specify which "component" you want the script to build and install.

The following options are available:

- `--install-plib`: Installs Plib
- `--install-osg`: Installs OpenSceneGraph
- `--install-osgxr`: Install osgXR, enabled VR support in FlightGear
- `--install-simgear`: Install SimGear
- `--install-flightgear`: Installs FlightGear

FlightGear depends on SimGear, OSG and Plib.

SimGear depends on OSG.

osgXR depends on OSG.

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
- `--no-config` | Will not create a custom configuration file for FlightGear.

The script should be clever enough to find the main software to build FlightGear, things like `gcc`, `cmake`, `git` and so on.

Specific dependencies will be pointed out by each component's own cmake however.

By the way, `--help`. Try it.

