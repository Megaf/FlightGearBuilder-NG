#!/bin/bash

# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                          FlightGearBuilder-NG.sh                          ║
# ╠═══════════════════════════════════════════════════════════════════════════╣
# ║ AUTHOR: Megaf - mmegaf[at]gmail[dot][com] - https://www.github.com/Megaf/ ║
# ║ DATE: 11/09/2023                                                          ║
# ║ LICENSE: GPL 3                                                            ║
# ╠═══════════════════════════════════════════════════════════════════════════╣
# ║ DESCRIPTION: This started as a simple an straightforward shell script     ║
# ║ that builds stuff from the source.                                        ║
# ║ It will download the source code for stuff, check some dependencies and   ║
# ║ compile them.                                                             ║
# ║ As the name suggests, this will build the FlightGear Flight Simulator.    ║
# ║ It will download and build Plib, OpenSceneGraph, SimGear and FlightGear.  ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# TODO: REPLACE ALL `ECHO` WITH SUITABLE `PRINTF`.
# TODO: ADD FILES AND DIRS CREATED BY INSTALLER TO INSTALLEDFILES.
# TODO: ADD NOTICE LEVEL.
# TODO: TRYING TO FIGURE OUT HOW TO, IN ONE LINE, SEE IF THERE'S ANY VALID ARG.
# TODO: ADD DEPENDENCIES FOR PLIB AND OSG.
# TODO: ADD MORE COMMENTS TO THE CODE.
# TODO: ADD UNINSTALL CAPABILITY.
# TODO: ADD OPTION TO BUILD AND ENABLE OPENTRACK.
# TODO: ADD OPTIONS TO INSTALL `.desktop` SHORTCUTS.

commandlineArguments=( "$@" )

clear

# Prints current time, used for simple console output.
now() {
  echo "{$(date +%H:%M:%S)} " # "hh:mm:ss"
}


print() { printf '%s\n' "${*}"; }


tell() {
  # This function will write text type and text given by two inputs.
  # It will colour the text and highlight status according to status type.
  # TODO: CODE BELOW IS UGLY AND WRONG. IT WORKS, BUT IT SUCKS. MAKE IT BETTER.
  # DEBUG: is only shown when `debug=true`
  local status
  local text
  status="${1}"
  text="${2}"
  # Dirty way of setting some colours.
  blue="\e[34m" green="\e[32m" red="\e[31m" rst="\e[0m"
  nu="\e[4m" bold="\e[1m" nn="\e[24m" nb="\e[22m"
  # Will print text with type read by `case` who sets formatting.
  _print() { echo -e "${1}-- $(now)${2}[${status}] ${3}${text}${nn}.\e[0m"; }
  case "${status}" in
    "DEBUG")
      [ "${debug}" = true ] && _print "${rst}" "${bold}${blue}" "${nb}"
      ;;
    "INFO")
      [ "${info}" = true ] && _print "${rst}" "${bold}${green}" "${nb}"
      ;;
    "ERROR")
      [ "${status}" = "ERROR" ] && _print "${rst}" "${bold}${red}" "${nu}${nb}"
      ;;
    *)
      _print "${rst}" "${bold}${blue}" "${nb}"
      ;;
  esac
}

# Walks though the command line arguments and do stuff.
# Sets script behaviors by setting those variables.
for commandlineArgument in "${commandlineArguments[@]}"; do
  case "${commandlineArgument}" in
    "--help")
      tell "DEBUG" "Help set"
      help=true
      shift
      ;;
    "--debug")
      debug=true
      tell "DEBUG" "Debug messages enabled"
      shift
      ;;
    "--install-dir="*)
      prefix="$(printf '%s' "${commandlineArgument}" | cut -d "=" -f 2)"
      shift
      tell "INFO" "Installing to: ${prefix}"
      export prefix
      ;;
    "--next"|"--nightly")
      shift
      projectVersion="next"
      flightgearBranch="next"
      osgBranch="master"
      tell "INFO" "Will build version \"Next\""
      ;;
    "--ninja")
      tell "DEBUG" "Using Ninja instead of Make"
      ninja=true
      shift
      ;;
    "--no-download")
      tell "DEBUG" "Download disabled"
      download=false
      shift
      ;;
    "--no-check-packages")
      tell "DEBUG" "Check packages enabled"
      checkpackages=false
      shift
      ;;
    "--full-check-packages")
      tell "DEBUG" "Full check packages enabled"
      checkpackages=full
      shift
      ;;
    "--no-check-dependencies")
      tell "DEBUG" "Check dependencies disabled"
      checkdepends=false
      shift
      ;;
    "--no-cmake")
      tell "DEBUG" "CMake disabled"
      cmake=false
      shift
      ;;
    "--no-compile")
      tell "DEBUG" "Compile disabled"
      compile=false
      shift
      ;;
    "--no-config")
      tell "DEBUG" "Config generator disabled"
      config=false
      shift
      ;;
    "--no-install")
      tell "DEBUG" "Install disabled"
      install=false
      shift
      ;;
  esac
done

help_text="FlightGearBuilder-NG Version 202310

This program installs FlightGear from its source code.
It will will download the source code and compile the following:
- Plib
- OpenSceneGraph
- SimGear
- FlightGear

Components: Dependencies that FlightGearBuilder-NG can install.
--install-plib          => Selects Plib for installation.
--install-osg           => Selects OpenSceneGraph for instalation.
--install-simgear       => Selects SimGear for installation.
--install-flightgear    => Selects FlightGear for installation.

Options: The following uptions must be specified BEFORE listing the desired \
components.
--help                  => This help page.
--debug                 => Enables FlightGearBuilder's debug messages.
--install-dir=/path     => Specifies where FlightGear should be installed.
--next                  => Builds the development version of FlightGear.
--ninja                 => Uses Ninja instead of Make.
--no-download           => Don't download nor update source codes.
--no-check-packages     => Skips installed dependencies check.
--full-check-packages   => Perform a full dependency check for the Qt launcher.
--no-check-dependencies => Skips checking if required components were installed.
--no-cmake              => Skips running cmake.
--no-compile            => Skips compiling.
--no-install            => Skips installing.
--no-config             => Skips FlightGear-Builder-NG's custom configuration.

Usage: You must specify the components you want FlightGearBuilder-NG to build.
./FlightGearBuild-NG.sh --install-plib --install-osg --install-simgear \
--install-flightgear --install-fgdata
"

[ -z "${info}" ] && info=true
[ -z "${debug}" ] && debug=false
[ -z "${dev}" ] && dev=false
[ -z "${download}" ] && download=true
[ -z "${checkpackages}" ] && checkpackages=true
[ -z "${checkdepends}" ] && checkdepends=true
[ -z "${cmake}" ] && cmake=true
[ -z "${compile}" ] && compile=true
[ -z "${install}" ] && install=true
[ -z "${config}" ] && config=true
[ -z "${uninstall}" ] && uninstall=false


projectName="FlightGear"                             # Thing that will be built
plibBranch="master"                                  # Plib Branch
[ -z "${projectVersion}" ] && projectVersion="2020.3"             # FG's Version
[ -z "${osgBranch}" ] && osgBranch="OpenSceneGraph-3.6"           # OSG Branch
[ -z "${flightgearBranch}" ] && flightgearBranch="release/2020.3" # FG Branch
fullName="${projectName}-${projectVersion}"          # Thing's full name
targetCPU="haswell"                                  # Optimizing for this CPU
minimalCPU="haswell"                                 # Runs on this or better
[ -z "${prefix}" ] && rootDirectory="${HOME}/${projectName}"      # Install dir
[ -n "${prefix}" ] && rootDirectory="${prefix}/${projectName}"    # Install dir
installDirectory="${rootDirectory}/${fullName}"      # Subdirectory
sourcecodeDirectory="${rootDirectory}/SourceCode"    # Put source code here
buildfilesDirectory="${installDirectory}/BuildFiles" # Put build stuff here
sourceDir() { print "${sourcecodeDirectory}/${1}"; }  # Get source dir for this
buildDir() { print "${buildfilesDirectory:?}/${1}"; } # And build dir for this
dataDirectory="${rootDirectory}/Data"                # FG's Data dir here
aircraftDirectory="${rootDirectory}/Aircraft"        # FG's Aircraft here
fghomeDirectory="${rootDirectory}/FG_HOME"           # FG's Settings here
fgfsrcFile="${fghomeDirectory}/fgfsrc"               # FG's "configuration" file
downloadsDirectory="${rootDirectory}/Downloads"      # FG's Download dir
terrasyncDirectory="${downloadsDirectory}/TerraSync" # FG's TerraSync dir
fileList="${installDirectory}/InstalledFiles.txt"    # List of every single file
launcherFile="${installDirectory}/flightgear-${projectVersion}"  # FG's launcher

## Defining directories needed by FlightGear
flightgearDirectories=(
  "${fghomeDirectory}"
  "${dataDirectory}"
  "${terrasyncDirectory}"
  "${downloadsDirectory}"
  "${aircraftDirectory}"
)

#### Git Definitions ####
gitJobs=16                                           # Simultaneous Git Jobs
# Git Addresses for each component. "git://git.code.sf.net/p/flightgear"
flightgearGit="https://gitlab.com/flightgear"
plibAddress="git://git.code.sf.net/p/libplib/code"
osgAddress="https://github.com/openscenegraph/OpenSceneGraph.git"
simgearAddress="${flightgearGit}/simgear.git"
flightgearAddress="${flightgearGit}/flightgear.git"
fgdataAddress="${flightgearGit}/flightgear/fgdata.git"

#### Compiler Definitions ####
# CPU and IO Priority for the compiler
# Build Scheduling priority: -20 to 19. Larger = Less priority.
cpuPriority="19"
# Build IO priority: Idle(3), Best-effort(2), Realtime(1), None(0).
ioPriority="3"
compilerJobs="$(nproc)"                              # Simultaneous Build Jobs
buildType="Release"                                  # Build type cmake option
cmakeOptions=(
  "-Wno-dev"                                         # Disable warnings in CMake
)

#### Compiler Flags ####
cFlags="-w -pipe -Oz -DNDEBUG -funroll-loops -march=${minimalCPU} \
-mtune=${targetCPU} -fomit-frame-pointer \
-mfpmath=sse -mssse3 -msse4.2 -mavx2 -mfma"          # C Flags
cxxFlags="${cFlags}"                                 # C++ Flags
glLibrary="GLVND"                                    # GL Lib # LEGACY
export PATH="/usr/lib/ccache:$PATH"
export CC="/usr/lib/ccache/x86_64-linux-gnu-gcc"
export CXX="/usr/lib/ccache/x86_64-linux-gnu-g++"
export LDFLAGS="-Wl,--copy-dt-needed-entries \
-Wl,-s"                                              # Linker flags

#### CMake flags for each target ####
# Common flags for all targets
commonCMakeFlags=(
  "-DCMAKE_BUILD_TYPE:STRING=${buildType}"
  "-DCMAKE_INSTALL_PREFIX:PATH=${installDirectory}"
  "-DCMAKE_C_FLAGS:STRING=${cFlags}"
  "-DCMAKE_CXX_FLAGS:STRING=${cxxFlags}"
)


# Plib flags
plibFlags=(
  "-DOpenGL_GL_PREFERENCE=${glLibrary}"
)

# OpenSceneGraph flags
osgFlags=(
  "-DOpenGL_GL_PREFERENCE=${glLibrary}"
  "-DBUILD_DASHBOARD_REPORTS:BOOL=ON"
  "-DOSG_USE_DEPRECATED_API:BOOL=OFF"
  "-DBUILD_OSG_APPLICATIONS:BOOL=OFF"
  "-DBUILD_OSG_DEPRECATED_SERIALIZERS:BOOL=OFF"
  "-DBUILD_OSG_PLUGINS_BY_DEFAULT:BOOL=OFF"
  "-DOSG_USE_DEPRECATED_API:BOOL=OFF"
  "-DOSG_AGGRESSIVE_WARNINGS:BOOL=OFF"
  "-DOSG_FIND_3RD_PARTY_DEPS:BOOL=OFF"
  "-DOSG_PLUGIN_SEARCH_INSTALL_DIR_FOR_PLUGINS:BOOL=OFF"
  "-DCMAKE_STRIP:BOOL=ON"
  "-DBUILD_TESTING:BOOL=OFF"
  "-DBUILD_DOCUMENTATION:BOOL=OFF"
  "-DASIO_INCLUDE_DIR:PATH="
  "-DCOLLADA_INCLUDE_DIR:PATH="
  "-DFBX_INCLUDE_DIR:PATH="
  "-DFFMPEG_LIBAVCODEC_INCLUDE_DIRS:PATH="
  "-DFFMPEG_LIBAVDEVICE_INCLUDE_DIRS:PATH="
  "-DFFMPEG_LIBAVFORMAT_INCLUDE_DIRS:PATH="
  "-DFFMPEG_LIBAVRESAMPLE_INCLUDE_DIRS:PATH="
  "-DFFMPEG_LIBAVUTIL_INCLUDE_DIRS:PATH="
  "-DFFMPEG_LIBSWRESAMPLE_INCLUDE_DIRS:PATH="
  "-DFFMPEG_LIBSWSCALE_INCLUDE_DIRS:PATH="
  "-DGIFLIB_INCLUDE_DIR:PATH="
  "-DGTA_INCLUDE_DIRS:PATH="
  "-DILMBASE_INCLUDE_DIR:PATH="
  "-DINVENTOR_INCLUDE_DIR:PATH="
  "-DLIBLAS_INCLUDE_DIR:PATH="
  "-DLIBVNCSERVER_INCLUDE_DIR:PATH="
  "-DOPENCASCADE_INCLUDE_DIR:PATH="
  "-DOPENEXR_INCLUDE_DIR:PATH="
  "-DSDL2_INCLUDE_DIR:PATH="
  "-DSDL_INCLUDE_DIR:PATH="
  "-DBUILD_OSG_PLUGIN_JPEG:BOOL=ON"
  "-DBUILD_OSG_PLUGIN_PNG:BOOL=ON"
  "-DBUILD_OSG_PLUGIN_AC:BOOL=ON"
  "-DBUILD_OSG_PLUGIN_BMP:BOOL=ON"
  "-DBUILD_OSG_PLUGIN_STL:BOOL=ON"
  "-DBUILD_OSG_PLUGIN_TIFF:BOOL=ON"
  "-DBUILD_OSG_PLUGIN_FREETYPE:BOOL=ON"
  "-DBUILD_OSG_PLUGIN_RGB:BOOL=ON"
  "-DBUILD_OSG_PLUGIN_TF:BOOL=ON"
  "-DBUILD_OSG_PLUGIN_TXF=ON"
  "-DBUILD_OSG_PLUGIN_DDS=ON"

)

# SimGear flags
simgearFlags=(
  "-DENABLE_SIMD_CODE:BOOL=OFF"
  "-DENABLE_TESTS:BOOL=OFF"
  "-DENABLE_GDAL:BOOL=OFF"
  "-DSYSTEM_EXPAT:BOOL=OFF"
  "-DENABLE_PKGUTIL:BOOL=OFF"
  "-DSIMGEAR_SHARED:BOOL=ON"
  "-DSIMGEAR_HEADLESS:BOOL=OFF"
  "-DENABLE_RTI:BOOL=OFF"
)

# FlightGear flags
flightgearFlags=(
  "-DBUILD_TESTING:BOOL=OFF"
  "-DENABLE_AUTOTESTING:BOOL=OFF"
  "-DENABLE_FGCOM:BOOL=OFF"
  "-DENABLE_DEMCONVERT:BOOL=OFF"
  "-DENABLE_FGELEV:BOOL=OFF"
  "-DENABLE_FGJS:BOOL=OFF"
  "-DENABLE_FGQCANVAS:BOOL=OFF"
  "-DENABLE_FGVIEWER:BOOL=OFF"
  "-DENABLE_GPSSMOOTH:BOOL=OFF"
  "-DENABLE_JS_DEMO:BOOL=OFF"
  "-DENABLE_METAR:BOOL=OFF"
  "-DENABLE_STGMERGE:BOOL=OFF"
  "-DSYSTEM_GSM:BOOL=OFF"
  "-DENABLE_TERRASYNC:BOOL=OFF"
  "-DENABLE_TRAFFIC:BOOL=OFF"
  "-DSYSTEM_SPEEX:BOOL=OFF"
  "-DWITH_FGPANEL:BOOL=OFF"
  "-DFG_BUILD_TYPE:STRING=Release"
  "-DENABLE_SWIFT:BOOL=ON"
  "-DENABLE_QT:BOOL=ON"
)

#### Dependencies needed to run this script and build Thing ####
# Basically, here we will use `which` to check if those are installed
generalDependencies=(
  "gcc"     "g++"   "cmake"   "make"    "ccache"
  "git"     "ls"    "rm"      "mkdir"   "echo"
  "chmod"   "cp"
)

packagesRequired=(
  "libjsoncpp-dev"    "libbz2-dev"    "libexpat1-dev"   "libswscale-dev"
  "libncurses5-dev"   "procps"        "zlib1g-dev"      "libarchive-dev"
  "build-essential"   "libssl-dev"    "git"             "freeglut3-dev"
  "libglew-dev"       "libopenal-dev" "libboost-dev"    "libavcodec-dev"
  "libavutil-dev"     "liblzma-dev"   "libavformat-dev" "libudev-dev"
  "libdbus-1-dev"     "libpng-dev"    "libjpeg-dev"     "cmake"
  "gcc"               "g++"           "librsvg2-dev"    "libgles2-mesa-dev"
  "libgudev-1.0-dev"  "liblua5.2-dev" "ccache"          "libevdev-dev"
  "libinput-dev"      "libgif-dev"    "libtiff-dev"     "libfreetype-dev"
  "libxmu-dev"        "libxi-dev"     "libxinerama-dev" "libfontconfig-dev"
  "libopenal-dev"     "libapr1-dev"
)


packagesOptional=(
  "libqt5opengl5-dev"   "qml-module-qtquick-controls2"  "libqt5websockets5-dev"
  "qtdeclarative5-dev"  "qml-module-qtquick-dialogs"    "qttools5-dev"
  "qttools5-dev-tools"  "qml-module-qtquick2"           "libqt5quick5"
  "qtbase5-dev-tools"   "qml-module-qtquick-window2"    "libqt5svg5-dev"
  "qtchooser"           "qtdeclarative5-private-dev"    "qtbase5-private-dev"
)

#### Individual Dependencies ####
# Those will be checked with `if [ -f "${file}" ]`
#plibDependencies=(
#  ""
#)

#osgDependencies=(
#  ""
#)

simgearDependencies=(
  "${installDirectory}/lib/libosg.so"
  "${installDirectory}/lib/libosgViewer.so"
)

flightgearDependencies=(
  "${installDirectory}/lib/libplibfnt.a"
  "${installDirectory}/lib/libosgText.so"
  "${installDirectory}/lib/libSimGearCore.so"
  "${installDirectory}/lib/libSimGearScene.so"
)

# Stuff that this script will be able to build.
# This is used later to validate install options.
availableComponents=(
  "plib"
  "osg"
  "simgear"
  "flightgear"
  "fgdata"
)

fgcolor() {
  # Calculates colour intensity level.
  # This function gets a colour and brightness intensity and outputs
  # RGB colour value for each brightness step inside the loop.
  local color="${1}"
  local lit="${2}"

  # FlightGear's colour palette.
  # blue="66;126;191"
  # yellow="254;255;71"
  # white="250;248;254"
  # gray="35;28;42"

  # Proportionally adjusts RGB value. Outputting RGB in RRR;GGG;BBB, 0..255.
  # Used by other functions inside `\e[38(or48);2(24 bit);RRR;GGG;BBBm`
  case "${color}" in
    "blue")
      echo "$((lit * 66 / 100));$((lit * 126 / 100));$((lit * 191 / 100))"
      ;;
    "yellow")
      echo "$((lit * 254 / 100));$((lit * 255 / 100));$((lit * 71 / 100))"
      ;;
    "white")
      echo "$((lit * 250 / 100));$((lit * 248 / 100));$((lit * 254 / 100))"
      ;;
    "gray")
      echo "$((lit * 35 / 100));$((lit * 28 / 100));$((lit * 42 / 100))"
      ;;
  esac
}


DrawText() {
  # Draws text with a fade in effect.
  local text="${1}"
  local color
  echo -en "\e[s"
  for shade in {0..100}; do
    color="$(fgcolor "blue" "${shade}")"
    echo -en "\e[u\e[0m\e[1m\e[38;2;${color}m${text}\e[0m"
    print
    sleep "0.01"
  done
}


FullFG() {
  # Draws the FlightGear logo on the terminal with a fade in effect.

  if [[ ${COLORTERM} ]]; then

    # Variables used to store colour values.
    local blue
    local white
    local yellow
    local gray

    echo -en "\e[s"   # Stores cursor's position.

    # For each brightness level, 0 to 100, calculate R;G;B value relative to it.
    for level in {0..100}; do

      blue="$(fgcolor "blue" "${level}")"
      yellow="$(fgcolor "yellow" "${level}")"
      white="$(fgcolor "white" "${level}")"
      gray="$(fgcolor "gray" "${level}")"

      # These functions will simply fill colour to the background
      # with " " according to values above.
      BB() { echo -en "\e[48;2;000;000;000m \e[0m"; }  # Black   Background
      GB() { echo -en "\e[48;2;${gray}m \e[0m"; }      # Gray    Background
      YB() { echo -en "\e[48;2;${yellow}m \e[0m"; }    # Yellow  Background
      CB() { echo -en "\e[48;2;${blue}m \e[0m"; }      # ~B~Clue Background
      WB() { echo -en "\e[48;2;${white}m \e[0m"; }     # White   Background
      NL() { echo -e "\e[0m"; }                        # New     Line

      echo -en "\e[u" # Moves back to previously stored cursor position.

      # Finally, draws the logo.
      CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;NL
      CB;YB;YB;BB;BB;YB;YB;WB;WB;WB;WB;WB;WB;WB;WB;WB;WB;CB;CB;CB;NL
      CB;BB;BB;YB;YB;BB;BB;WB;WB;CB;CB;CB;CB;CB;CB;WB;WB;GB;GB;CB;NL
      CB;YB;YB;BB;BB;YB;YB;WB;WB;CB;CB;WB;WB;WB;WB;WB;WB;GB;GB;CB;NL
      CB;BB;BB;YB;YB;BB;BB;WB;WB;CB;CB;CB;CB;CB;WB;WB;WB;GB;GB;CB;NL
      CB;YB;YB;BB;BB;YB;YB;WB;WB;CB;CB;WB;WB;WB;WB;WB;WB;GB;GB;CB;NL
      CB;BB;BB;YB;YB;BB;BB;WB;WB;CB;CB;WB;WB;WB;WB;WB;WB;GB;GB;CB;NL
      CB;YB;YB;BB;BB;YB;YB;WB;WB;WB;WB;WB;WB;WB;WB;WB;WB;GB;GB;CB;NL
      CB;BB;BB;YB;YB;BB;BB;WB;WB;WB;WB;WB;WB;WB;WB;WB;WB;GB;GB;CB;NL
      CB;CB;CB;GB;GB;GB;GB;GB;GB;GB;GB;GB;GB;GB;GB;GB;GB;GB;GB;CB;NL
      CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;CB;NL

      sleep "0.01"

    done
    NL
  else
	local _f="
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▒▒░░▒▒██████████▓▓▓
▓░░▒▒░░██▒▒▒▒▒▒██░░▓
▓▒▒░░▒▒██▒▒██████░░▓
▓░░▒▒░░██▒▒▒▒▒███░░▓
▓▒▒░░▒▒██▒▒██████░░▓
▓░░▒▒░░██▒▒██████░░▓
▓▒▒░░▒▒██████████░░▓
▓░░▒▒░░██████████░░▓
▓▓▓░░░░░░░░░░░░░░░░▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
"
    echo "${_f}"
  fi
}



#### Script's business side starts here ####
# DependsCheck, Get, CMake, Compile and Install functions,
# will only run if their flags=true,
# For example: `download=true`, `compile=true`
#
# DependsCheck = verifies dependencies are installed
# Get = Downloads codes from Git, `git clone` `git pull` `git checkout`
# CMake = Runs `cmake` using flags from the array
# Compile = Runs `make -j $(nproc)`
# Install = Runs `make install` and creates other files for the final program
tell "DEBUG" "Variables set. Program Start."

makedir() {
  # Safely make dirs and exit if it can't.
  local thing
  thing="${1}"
  tell "DEBUG" "Creating directory \"${thing}\"."
  if mkdir -p "${thing}"; then
    tell "DEBUG" "Directory \"${thing}\" created."
  else
    tell "ERROR" "Failed to create directory \"${thing}\"."
    exit 1
  fi
}


delete() {
  # Safely delete dirs and files and exit if it can't
  local thing
  thing="${1}"
  tell "DEBUG" "Deleting \"${thing}\"."
  if rm -rf "${thing:?}"; then
    tell "DEBUG" "${thing} deleted."
  else
    tell "ERROR" "Failed to delete \"${thing}\"."
    exit 1
  fi
}


enterdir() {
  # Safely enter dirs and exit if it can't
  local thing
  thing="${1}"
  tell "DEBUG" "Entering directory \"${thing}\"."
  if cd "${thing}"; then
    tell "DEBUG" "Entered directory \"${thing}\"."
  else
    tell "ERROR" "Failed to enter directory \"${thing}\"."
    exit 1
  fi
}


MakeConfig() {
  # This will generate a `fgfsrc` (https://wiki.flightgear.org/Fgfsrc)
  # Settings adequate for old 64 bit CPUs, such as a Pentium 4 and Athlon 64.
  if [ "${config}" = true ]; then
    tell "DEBUG" "Enter MakeConfig."
    tell "INFO" "Installing ${fgfsrcFile}"
    delete "${fgfsrcFile}"
    cat << EOF > "${fgfsrcFile}"
--enable-sentry
--prop:/sim/tile-cache/enable=false
--prop:/sim/nasal-gc-threaded=true
--prop:/sim/current-view/field-of-view-compensation=true
#--prop:/sim/rendering/multithreading-mode=CullThreadPerCameraDrawThreadPerContext
--prop:/sim/rendering/multithreading-mode=DrawThreadPerContext
#--prop:/sim/rendering/multithreading-mode=CullDrawThreadPerContext
#--prop:/sim/rendering/multithreading-mode=SingleThreaded
--prop:/sim/rendering/filtering=4
--prop:/sim/rendering/multi-sample-buffers=true
--prop:/sim/rendering/multi-samples=4
--prop:/sim/rendering/camera-group/znear=0.04
--prop:/environment/contrail=true
--prop:/scenery/share-events=true
--prop:/sim/rendering/use-vbos=true
--prop:/sim/startup/xsize=1280
--prop:/sim/startup/ysize=720
--prop:/sim/rendering/random-vegetation-optimize=true
--prop:/sim/rendering/building-density=0.1
--prop:/sim/rendering/als/shadows/enabled=true
--prop:/sim/rendering/als/shadows/sun-atlas-size=2048
--prop:/sim/rendering/max-paged-lod=2
--prop:/sim/rendering/static-lod/detailed=1000
--prop:/sim/rendering/static-lod/rough-delta=4000
--prop:/sim/rendering/static-lod/bare-delta=75000
--prop:/sim/rendering/horizon-effect=true
--prop:/sim/rendering/enhanced-lighting=true
--prop:/sim/rendering/distance-attenuation=true
--prop:/sim/rendering/precipitation-gui-enable=true
--prop:/sim/rendering/precipitation-enable=true
--prop:/sim/rendering/lightning-enable=true
--prop:/sim/rendering/specular-highlight=true
--prop:/sim/rendering/bump-mapping=true
--prop:/sim/rendering/shadows-ac=true
--prop:/sim/rendering/shadows-ac-transp=true
--prop:/sim/rendering/shadows-ai=true
--prop:/sim/rendering/shadows-to=true
--prop:/sim/rendering/clouds3d-vis-range=80000
--prop:/sim/rendering/clouds3d-detail-range=5000
--prop:/sim/rendering/clouds3d-density=0.22
--prop:/sim/rendering/shadows/enabled=true
--prop:/sim/rendering/shadows/filtering=4
--prop:/sim/rendering/headshake/enabled=true
--prop:/sim/rendering/pilot-model=enabled=false
--prop:/sim/rendering/texture-cache/cache-enabled=true
--prop:/sim/rendering/texture-cache/compress-transparent=false
--prop:/sim/rendering/texture-cache/compress-solid=false
--prop:/sim/rendering/texture-cache/compress=false
--prop:/sim/menubar/visibility=true
--prop:/sim/menubar/autovisibility/enabled=true
--prop:/sim/gui/chat-box-location=left
--prop:/sim/mouse/hide-cursor=true
--prop:/sim/mouse/cursor-timeout-sec=2
--prop:/sim/traffic-manager/enabled=false
--prop:/sim/ai/scenarios-enabled=false
--prop:/sim/terrasync/ai-data-update=0
--prop:/sim/terrasync/ai-data-enabled=0
--prop:/local-weather/config/asymmetric-buffering-flag=true
--prop:/local-weather/config/distance-to-load-tile-m=120000
--prop:/local-weather/config/distance-to-remove-tile-m=120000
--prop:/local-weather/config/detailed-clouds-flag=true
--prop:/local-weather/config/max-vis-range-m=80000
--prop:/sim/sound/atc/enabled=false
--prop:/sim/sound/atc/external-view/enabled=false
--fog-nicest
--shading-smooth
--enable-clouds3d
--enable-clouds
--visibility=80000
EOF
    echo "${fgfsrcFile}" >> "${fileList}"  # Adds fgfsrc file path to file list
  else
    tell "DEBUG" "config=false"
  fi
  return 0
}

Get() {
  # This function is a "Code downloader for Git" (tm).
  # It checks if the code has already been cloned, if so, it checkouts the right
  # branch and updates it, if not downloaded, then it downloads it.
  local this="${1}"
  local url="${2}"
  local branch="${3}"
  if [ "${download}" = true ]; then
    tell "DEBUG" "Enter Get."
    if [ -d "$(sourceDir "${this}")" ]; then
      tell "INFO" "Updating \"${this}\""
      enterdir "$(sourceDir "${this}")"
      tell "INFO" "Checking if the source code of \"${this}\" was changed."
      if git diff --exit-code &> /dev/null; then
        git fetch origin --jobs="${gitJobs}"
        git checkout --force "${branch}"
        git pull --rebase --jobs="${gitJobs}"
      else
        tell "INFO" "Changes detected, stashing them."
        git fetch origin --jobs="${gitJobs}"
        git stash save --include-untracked --quiet
        git checkout --force "${branch}"
        git pull --rebase --jobs="${gitJobs}"
        git stash pop --quiet
      fi
    else
      tell "INFO" "Downloading \"${this}\" source code."
      makedir "${sourcecodeDirectory}"
      git clone -b "${branch}" -j "${gitJobs}" "${url}" "$(sourceDir "${this}")"
      if [ "${this}" = "plib" ]; then
        tell "DEBUG" "\"${this}\" detected, doing version stuff."
        enterdir "$(sourceDir "${this}")"
        print "1.8.6" > version
        sed s/PLIB_TINY_VERSION\ \ 5/PLIB_TINY_VERSION\ \ 6/ -i src/util/ul.h
        git commit --all --message "Increase tiny version to 6."
        return 0
      fi
    fi
    tell "DEBUG" "Get concluded."
  else
    tell "DEBUG" "download=false"
  fi
  return 0
}


CMake() {
  # Runs CMake for each component using flags defined in the arrays elsewhere.
  local thing="${1}"
  local -a targetFlags=("${@:2}")
  if [ "${cmake}" = true ]; then
    tell "DEBUG" "Enter CMake."
    tell "INFO" "Running CMake for \"${thing}\""
    if [ -d "$(buildDir "${thing}")" ]; then
      tell "DEBUG" "Deleting build directory for ${thing}"
      rm -rf "$(buildDir "${thing}")"
    fi
    makedir "$(buildDir "${thing}")"
    enterdir "$(buildDir "${thing}")"
    tell "DEBUG" "Setting main CMake cmakeFlags"
    tell "DEBUG" "commonCMakeFlags=${commonCMakeFlags[*]}"
    tell "DEBUG" "${thing}'s cmakeFlags set to ${targetFlags[*]}'"
    cmake "${cmakeOptions[@]}" "$(sourceDir "${thing}")" \
    "${targetFlags[@]}" || exit 1
  else
    tell "DEBUG" "cmake=false"
  fi
  return 0
}


Make() {
  # Runs either `ninja/make` or `ninja/make install` for the selected component.
  local thing="${1}"
  local makeCommand="${2}"
  tell "DEBUG" "Enter Make"
  case "${makeCommand}" in
    "compile")
      tell "INFO" "Compiling \"${thing}\""
      if nice -n "${cpuPriority}" ionice -c "${ioPriority}" \
      "${_make}" -j "${compilerJobs}"; then
        tell "INFO" "\"${thing}\" compiled successfully"
      else
        tell "ERROR" "\"${thing}\" failed to compile"
      exit 1
    fi
    ;;
    "install")
      tell "INFO" "Installing \"${thing}\""
      if "${_make}" install; then
        tell "INFO" "\"${thing}\" installed successfully."
      else
        tell "ERROR" "\"${thing}\" failed to install."
        exit 1
      fi
    ;;
  esac
  return 0
}


Compile() {
  # Runs `make`
  local thing="${1}"
  if [ "${compile}" = true ]; then
    tell "DEBUG" "Enter Compile."
    enterdir "$(buildDir "${thing}")"
    Make "${thing}" "compile"
  else
    tell "DEBUG" "compile=false"
  fi
  return 0
}


Install() {
  # Will do `make install` and create extra files.
  local thing="${1}"
  if [ "${install}" = true ]; then
    tell "DEBUG" "Enter Install."
    tell "Installing" "\"${thing}\""
    enterdir "$(buildDir "${thing}")"
    Make "${thing}" "install"
    cat install_manifest.txt >> "${fileList}"
    if [ "${thing}" = "flightgear" ]; then
      for directoryName in "${flightgearDirectories[@]}"; do
        makedir "${directoryName}"
      done
      tell "INFO" "Installing: ${launcherFile}"
      local flightgearArguments=(
        "--fg-scenery=\${FG_ROOT}/Scenery/:\${FG_TERRASYNC}"
        "--download-dir=\${FG_DOWNLOAD}"
        "--terrasync-dir=\${FG_TERRASYNC}"
      )
      # Creates the "binary" to launch FlightGear
      cat << EOF > "${launcherFile}"
#!/bin/bash

################################################################################
#                                                                              #
# flightgear                                                                   #
#                                                                              #
################################################################################
#                                                                              #
# FlightGear launcher, built with FlightGearBuilder-NG                         #
# DO NOT EDIT                                                                  #
# All changes will be overwriten by FlightGearBuilder-NG                       #
#                                                                              #
################################################################################

print() { printf '%s\n' "\${*}"; }  # "Print" method
numberCores="\$(nproc)"  # Gets number of cores
gitJobs=\$((numberCores * 3))  # Set number of git jobs
branch="${flightgearBranch}"  # FGData Branch
installDir="${installDirectory}"

# Sets number of OSG DB Threads according to the number of cores.
databaseThreads=\$((numberCores * 2))
if [ "\${databaseThreads}" -gt 1 ]; then
  httpThreads=\$((databaseThreads / 2))
else
  httpThreads=1
fi

export OSG_NUM_DATABASE_THREADS="\${databaseThreads}"  # Threads Configuration
export OSG_NUM_HTTP_DATABASE_THREADS="\${httpThreads}"  # Threads Configuration
export LD_LIBRARY_PATH="\${installDir}/lib"  # Libraries directory
export PATH="\${installDir}/bin:\$PATH"  # FlightGear PATG
export FG_ROOT="${dataDirectory}"  # FlightGear Data
export FG_HOME="${fghomeDirectory}"  # Configuration Files
export FG_AIRCRAFT="${aircraftDirectory}"  # Aditional Aircraft
export FG_DOWNLOAD="${downloadsDirectory}"  # Extra Downloads
export FG_TERRASYNC="${terrasyncDirectory}"  # TerraSync Directory

if [ -d "\${installDir}" ]; then
    if [ -d "\${FG_ROOT}" ]; then
      print "Switching/Updating FGData to version \"\${branch}\"."
      cd "\${FG_ROOT}" || exit 1
      if git diff --exit-code &> /dev/null; then
        git fetch origin "\${branch}" --jobs="\${gitJobs}"
        git checkout --force -B "\${branch}" origin/"\${branch}"
        git pull --rebase --jobs="\${gitJobs}"
      else
        print "Changes to FGData detected, stashing them."
        git fetch origin "\${branch}" --jobs="\${gitJobs}"
        git stash save --include-untracked --quiet
        git checkout --force -B "\${branch}" origin/"\${branch}"
        git pull --rebase --jobs="\${gitJobs}"
        git stash pop --quiet
      fi
    else
      print "Error: Couldn't find FGData directory."
      exit 1
    fi
else
  print "Error: Couldn't find FlightGear Next, did you build it with --next?"
  exit 1
fi

# If the variable "debug" is true, FG will run on gdb.
if [ "\${debug}" ]; then
  fgfs() { gdb -w --args \${installDir}/bin/fgfs $*; }
else
  fgfs() { \${installDir}/bin/fgfs $*; }
fi

fgfs ${flightgearArguments[@]} \
--prop:/sim/rendering/database-pager/threads="\${databaseThreads}" \${*}
EOF
      chmod +x "${launcherFile}" || exit 1
      echo "${launcherFile}" >> "${fileList}" # Adds launcher path to file list
      MakeConfig || exit 1
    fi
  else
    tell "DEBUG" "install=false"
    return 0
  fi
  return 0
}


#Uninstall() {
#  # Removes all files listed in the installed files manifest.
#  local thing="${1}"
#  if [ "${uninstall}" = true ]; then
#    tell "DEBUG" "Enter UninstallProject"
#    if [ -f "${fileList}" ]; then
#      tell "INFO" "Uninstalling: ${thing}"
#      while IFS= read -r line; do
#        if [ -n "${line}" ]; then
#          tell "INFO" "Deleting: ${line}"
#          rm -rf "${line}"
#        fi
#      done < "${fileList}"
#      tell "INFO" "Uninstalling: ${thing} completed."
#    else
#      tell "ERROR" "Can't uninstall ${thing}, ${fileList} not found."
#      exit 1
#    fi
#  fi
#}


# Checks if the required packages are installed on the system.
PackagesCheck() {
  local -a packages=("${@:2}")
  local -a notfound=()
  local option
  if [ ! -e "/etc/debian_version" ]; then
    tell "ERROR" "We only support packges check on Debian"
    return 1
  fi
  for package in "${packages[@]}"; do
    tell "INFO" "Checking if \"${package}\" is installed"
    dpkg-query -s "${package}" &> /dev/null
    case "${?}" in
      0)  tell "INFO" "[OK]" ;;
      *)  tell "ERROR" "[Fail]"; notfound+=( "${package}" ) ;;
    esac
  done
  if [ "${#notfound[@]}" -gt 0 ]; then
    tell "ERROR" "Cound't find the [${notfound[*]}] package(s)"
    tell "INFO" "Would you like to try to install them?"
    tell "INFO" "Type \"y\" for yes or anything else for no."
    read -n 1 -r -s -t 60 option
    case "${option}" in
      "y")  sudo apt install "${notfound[@]}" ;;
      *)    exit 1  ;;
    esac
  fi
  return 0
}


# Check if the required files are installed on the system.
FilesCheck() {
  [ -f "${1}" ]
}


# Check if the required files are installed on the system.
CommandsCheck() {
  local thing="${1}"
  local -a dependenciesList=("${@:2}")
  local -a notfound=( )
  case "${checkdepends}" in
    "true")
      tell "DEBUG" "Enter CommandsCheck"
      tell "INFO" "Checking dependencies for \"${thing}\""
      for dependencyName in "${dependenciesList[@]}"; do
        tell "INFO" "Checking if \"${dependencyName}\" is installed"
        which "${dependencyName}" 1> /dev/null "${dependencyName}"
        case "${?}" in
          0)  tell "INFO" "[OK]" ;;
          *)  tell "ERROR" "[Fail]"; notfound+=( "\"${dependencyName}\"" ) ;;
        esac
      done
      ;;
    *)  tell "DEBUG" "checkdepends=false"
  esac
  if [ "${#notfound[@]}" -gt 0 ]; then
    tell "ERROR" "Make sure the following is installed: [${notfound[*]}]"
    exit 1
  fi
  return 0
}


# Check if required files from other compoments were installed.
DependsCheck() {
  local thing="${1}"
  local -a dependenciesList=("${@:2}")
  local -a notfound=( )
  case "${checkdepends}" in
    "true")
      tell "DEBUG" "Enter DependsCheck"
      tell "INFO" "Checking dependencies for \"${thing}\""
      for dependencyName in "${dependenciesList[@]}"; do
        tell "INFO" "Checking if \"${dependencyName}\" is installed"
        FilesCheck "${dependencyName}"
        case "${?}" in
          0)  tell "INFO" "[OK]" ;;
          *)  tell "ERROR" "[Fail]"; notfound+=( "\"${dependencyName}\"" ) ;;
        esac
      done
      ;;
    *)  tell "DEBUG" "checkdepends=false"
  esac
  if [ "${#notfound[@]}" -gt 0 ]; then
    tell "ERROR" "Cound't find the [${notfound[*]}] file(s)"
    exit 1
  fi
  return 0
}


_do() {
  # aka "function main()", runs the show.
  # For each component it will [do] the required action.
  local targetName="${1}"
  tell "DEBUG" "Enter _do."
  local url=""
  local branch=""
  # Use ninja as make command and tells cmake to generate a ninja buid
  # if ninja was enabled.
  case "${ninja}" in
    true)
      _make="ninja"
      local -a componentFlags=( "-G Ninja" "${commonCMakeFlags[@]}" )
      local -a packages=( "ninja" "${packagesRequired[@]}" )
      ;;
    *)
      _make="make"
      local -a componentFlags=( "${commonCMakeFlags[@]}" )
      local -a packages=( "${packagesRequired[@]}" )
      ;;
  esac
  case "${targetName}" in
    "plib")
      Get "${targetName}" "${plibAddress}" "${plibBranch}"
#      DependsCheck "${targetName}" "${plibDependencies[@]}"
      componentFlags+=( "${plibFlags[@]}" )
      CMake "${targetName}" "${componentFlags[@]}"
      Compile "${targetName}"
      Install "${targetName}"
      ;;
    "osg")
      Get "${targetName}" "${osgAddress}" "${osgBranch}"
#      DependsCheck "${targetName}" "${osgDependencies[@]}"
      componentFlags+=( "${osgFlags[@]}" )
      CMake "${targetName}" "${componentFlags[@]}"
      Compile "${targetName}"
      Install "${targetName}"
      ;;
    "simgear")
      Get "${targetName}" "${simgearAddress}" "${flightgearBranch}"
      DependsCheck "${targetName}" "${simgearDependencies[@]}"
      componentFlags+=( "${simgearFlags[@]}" )
      CMake "${targetName}" "${componentFlags[@]}"
      Compile "${targetName}"
      Install "${targetName}"
      ;;
    "flightgear")
      Get "${targetName}" "${flightgearAddress}" "${flightgearBranch}"
      DependsCheck "${targetName}" "${flightgearDependencies[@]}"
      componentFlags+=( "${flightgearFlags[@]}" )
      CMake "${targetName}" "${componentFlags[@]}"
      Compile "${targetName}"
      Install "${targetName}"
      ;;
    "fgdata")
      Get "${targetName}" "${fgdataAddress}" "${flightgearBranch}"
      ;;
    *)
      exit 1
      ;;
  esac
}


#### Show Starter ####
DrawText "Welcome to FlightGearBuilder-NG"           # Shows welcome message.
print
FullFG                                               # Fades FG logo in.

# Shows help if user either didn't chose any "install" option of if the user
# used the `--help` command argument.
if [[ ! "${*}" =~ "install" || "${help}" ]]; then
  print "${help_text}"
  exit 1
fi

# Checks if required packages are installed in the system.
# "full" also checks for required packages for the graphical Qt based launcher.
tell "INFO" "Checking if the minimum set of commands is available."
CommandsCheck "General Buld Deps" "${generalDependencies[@]}"

case "${checkpackages}" in
  "true")
    tell "INFO" "Checking for the required packages"
    PackagesCheck "${packagesRequired[@]}"
    ;;
  "full")
    fullPackages=( "${packagesRequired[@]}" "${packagesOptional[@]}" )
    tell "INFO" "Checking for all required and optional packages"
    PackagesCheck "${fullPackages[@]}"
    ;;
  "false")
    tell "DEBUG" "Check packages disabled"
    ;;
esac

# Walks through all command line arguments, and install each component in
# an ordered way.
# For that, it walks, in order, the "components" array and
# compares it to the argument.
# Executing the appropriate function accordingly.
for componentName in "${availableComponents[@]}"; do
  for comandlineArgument in "${commandlineArguments[@]}"; do
    if [[ "${comandlineArgument}" == --install-"${componentName}" ]]; then
      tell "DEBUG" "You've chosen to install ${comandlineArgument}"
      _do "${componentName}" || exit 1
    elif [[ "${comandlineArgument}" == --uninstall-"${componentName}" ]]; then
      tell "DEBUG" "You've chosen to uninstall ${comandlineArgument}"
      tell "INFO" "Uninstalling ${componentName}"
      Uninstall "${componentName}"
    fi
  done
done

# If all went well, cleanly exit.
exit 0 # Bye!
