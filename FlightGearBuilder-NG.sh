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
# TODO: Add dependencies for Plib and OSG.
# TODO: Add more comments to the code.
# TODO: Improve code spacing.
# TODO: Adjust launcher's code.
# TODO: Add install support for FGData.
# TODO: Make options for more limited colours and or black and white.
# TODO: Add Uninstall capability.
# TODO: Add proper help.

commandlineArguments=( "$@" )

# Prints current time, used for simple console output.
now() {
  echo "{$(date +%H:%M:%S)} " # "hh:mm:ss"
}


[ -z "${info}" ] && info=true
[ -z "${debug}" ] && debug=false
[ -z "${dev}" ] && dev=false
[ -z "${download}" ] && download=true
[ -z "${checkdepends}" ] && checkdepends=true
[ -z "${cmake}" ] && cmake=true
[ -z "${compile}" ] && compile=true
[ -z "${install}" ] && install=true
[ -z "${uninstall}" ] && uninstall=false

projectName="FlightGear"                             # Thing that will be built
projectVersion="2020.3"                              # Thing's version
fullName="${projectName}-${projectVersion}"          # Thing's full name
targetCPU="core2"                                    # Optimizing for this CPU
minimalCPU="core2"                                   # Runs on this or better
rootDirectory="/media/${USER}/${projectName}"        # Install Thing here
[[ "${TERMUX_VERSION}" ]] && rootDirectory="${HOME}" # Or here if Termux
installDirectory="${rootDirectory}/${fullName}"      # Actually, install here
sourcecodeDirectory="${installDirectory}/SourceCode" # Put source code here
buildfilesDirectory="${installDirectory}/BuildFiles" # Put build stuff here
sourceDir() { echo "${sourcecodeDirectory}/${1}"; }  # Get source dir for this
buildDir() { echo "${buildfilesDirectory:?}/${1}"; } # And build dir for this
dataDirectory="${installDirectory}/Data"             # FG's Data dir here
aircraftDirectory="${installDirectory}/Aircraft"     # FG's Aircraft here
fghomeDirectory="${installDirectory}/FG_HOME"        # FG's Settings here
fgfsrcFile="${installDirectory}/FG_HOME/fgfsrc"      # FG's "configuration" file
downloadsDirectory="${installDirectory}/Downloads"   # FG's Download dir
terrasyncDirectory="${downloadsDirectory}/TerraSync" # FG's TerraSync dir
fileList="${installDirectory}/InstalledFiles.txt"    # List of every single file
launcherFile="${installDirectory}/flightgear"        # FG's launcher'

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
# And their Branches
plibBranch="master"
osgBranch="OpenSceneGraph-3.6"
flightgearBranch="release/2020.3"

#### Compiler Definitions ####
# CPU and IO Priority for the compiler
# Build Scheduling priority: -20 to 19. Larger = Less priority.
cpuPriority="19"
# Build IO priority: Idle(3), Best-effort(2), Realtime(1), None(0).
ioPriority="3"
compilerJobs="$(nproc)"                              # Simultaneous Build Jobs
buildType="Release"                                  # Build type cmake option
# Disable compiler warnings in cmake
cmakeOptions=(
  "-Wno-dev"
)

#### Compiler Flags ####
cFlags="-w -pipe -O3 -DNDEBUG -funroll-loops \
-mfpmath=both -march=${minimalCPU} \
-mtune=${targetCPU}"                                 # C Flags
cxxFlags="${cFlags}"                                 # C++ Flags
glLibrary="LEGACY"                                   # Or GLVND, which is newer
PATH="/usr/lib/ccache:$PATH"                         # Enables compiler caching
export LDFLAGS="-Wl,--copy-dt-needed-entries \
-Wl,-s"                                              # FG won't link without it

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
  "-DBUILD_DASHBOARD_REPORTS:BOOL=OFF"
  "-DOSG_USE_DEPRECATED_API:BOOL=OFF"
  "-DBUILD_OSG_APPLICATIONS:BOOL=OFF"
  "-DBUILD_OSG_DEPRECATED_SERIALIZERS:BOOL=OFF"
  "-DBUILD_OSG_PLUGINS_BY_DEFAULT:BOOL=ON"
  "-DOSG_USE_DEPRECATED_API:BOOL=OFF"
  "-DOSG_AGGRESSIVE_WARNINGS:BOOL=OFF"
  "-DOSG_FIND_3RD_PARTY_DEPS:BOOL=OFF"
  "-DOSG_PLUGIN_SEARCH_INSTALL_DIR_FOR_PLUGINS:BOOL=OFF"
  "-DCMAKE_STRIP:BOOL=ON"
  "-DBUILD_DOCUMENTATION:BOOL=OFF"
)

# SimGear flags
simgearFlags=(
  "-DENABLE_SIMD_CODE:BOOL=ON"
  "-DENABLE_TESTS:BOOL=OFF"
  "-DENABLE_GDAL:BOOL=OFF"
  "-DSYSTEM_EXPAT:BOOL=OFF"
  "-DSYSTEM_UDNS:BOOL=ON"
  "-DUSE_SHADERVG:BOOL=OFF"
  "-DENABLE_PKGUTIL:BOOL=OFF"
)

# FlightGear flags
flightgearFlags=(
  "-DENABLE_TESTS:BOOL=OFF"
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
  "-DENABLE_PROFILE:BOOL=OFF"
  "-DENABLE_STGMERGE:BOOL=OFF"
  "-DSYSTEM_GSM:BOOL=OFF"
  "-DENABLE_TERRASYNC:BOOL=OFF"
  "-DENABLE_TRAFFIC:BOOL=OFF"
  "-DENABLE_VR:BOOL=OFF"
  "-DSYSTEM_OSGXR:BOOL=OFF"
  "-DSYSTEM_SPEEX:BOOL=OFF"
  "-DWITH_FGPANEL:BOOL=OFF"
  "-DFG_BUILD_TYPE:STRING=Release"
)

#### Dependencies needed to run this script and build Thing ####
# Basically, here we will use `which` to check if those are installed
generalDependencies=(
  "gcc"   "g++"   "cmake"   "make"    "ccache"
  "git"   "ls"    "rm"      "mkdir"   "echo"
  "chmod" "cp"
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
  "${installDirectory}/lib/libSimGearCore.a"
  "${installDirectory}/lib/libSimGearScene.a"
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
    echo
    sleep "0.01"
  done
}


FullFG() {
  # Draws the FlightGear logo on the terminal with a fade in effect.

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
}


tell() {
  # This function will write text type and text given by two inputs.
  # It will colour the text and highlight status according to status type.
  # TODO: Code below is ugly and wrong. It works, but it sucks. Make it better.
  # DEBUG: is only shown when `debug=true`
  local status
  local text
  status="${1}"
  text="${2}"
  # Dirty way of setting some colours.
  blue="\e[34m" green="\e[32m" red="\e[31m" rst="\e[0m"
  nu="\e[4m" bold="\e[1m" nn="\e[24m" nb="\e[22m"
  # Will print text with type read by `case` who sets formatting.
  print() { echo -e "${1}-- $(now)${2}[${status}] ${3}${text}${nn}.\e[0m"; }
  case "${status}" in
    "DEBUG")
      [ "${debug}" = true ] && print "${rst}" "${bold}${blue}" "${nb}"
      ;;
    "INFO")
      [ "${info}" = true ] && print "${rst}" "${bold}${green}" "${nb}"
      ;;
    "ERROR")
      [ "${status}" = "ERROR" ] && print "${rst}" "${bold}${red}" "${nu}${nb}"
      ;;
    *)
      print "${rst}" "${bold}${blue}" "${nb}"
      ;;
  esac
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
  tell "DEBUG" "Enter MakeConfig."
  tell "INFO" "Installing ${fgfsrcFile}"
  delete "${fgfsrcFile}"
  cat << EOF > "${fgfsrcFile}"
--enable-sentry
--enable-terrasync
--disable-ai-models
--disable-ai-traffic
--max-fps=30
--prop:/sim/tile-cache/enable=false
--prop:/sim/nasal-gc-threaded=true
--prop:/sim/current-view/field-of-view-compensation=true
--prop:/sim/rendering/multithreading-mode=CullDrawThreadPerContext
--prop:/sim/rendering/database-pager/threads=2
--prop:/sim/rendering/filtering=0
--prop:/sim/rendering/multi-sample-buffers=false
--prop:/sim/rendering/multi-samples=0
--prop:/environment/contrail=true
--prop:/scenery/share-events=true
--prop:/sim/rendering/use-vbos=false
--prop:/sim/startup/xsize=1280
--prop:/sim/startup/ysize=720
--prop:/sim/rendering/random-objects=false
--prop:/sim/rendering/random-vegetation=true
--prop:/sim/rendering/random-vegetation-shadows=false
--prop:/sim/rendering/random-vegetation-normals=false
--prop:/sim/rendering/random-vegetation-optimize=false
--prop:/sim/rendering/vegetation-density=0.1
--prop:/sim/rendering/random-buildings=false
--prop:/sim/rendering/osm-buildings=false
--prop:/sim/rendering/building-density=0.1
--prop:/sim/rendering/particles=false
--prop:/sim/rendering/als/shadows/enabled=false
--prop:/sim/rendering/als/shadows/sun-atlas-size=512
--prop:/sim/rendering/max-paged-lod=2
--prop:/sim/rendering/static-lod/detailed=500
--prop:/sim/rendering/static-lod/rough-delta=1000
--prop:/sim/rendering/static-lod/bare-delta=16000
--prop:/sim/rendering/static-lod/aimp-range-mode-distance=false
--prop:/sim/rendering/static-lod/aimp-detailed=0
--prop:/sim/rendering/static-lod/aimp-bare=0
--prop:/sim/rendering/static-lod/aimp-interior=0
--prop:/sim/rendering/horizon-effect=true
--prop:/sim/rendering/enhanced-lighting=false
--prop:/sim/rendering/distance-attenuation=true
--prop:/sim/rendering/precipitation-gui-enable=true
--prop:/sim/rendering/precipitation-enable=true
--prop:/sim/rendering/lightning-enable=false
--prop:/sim/rendering/specular-highlight=false
--prop:/sim/rendering/bump-mapping=false
--prop:/sim/rendering/shadows-ac=false
--prop:/sim/rendering/shadows-ac-transp=false
--prop:/sim/rendering/shadows-ai=false
--prop:/sim/rendering/shadows-to=false
--prop:/sim/rendering/clouds3d-vis-range=4000
--prop:/sim/rendering/clouds3d-detail-range=1000
--prop:/sim/rendering/clouds3d-density=0.05
--prop:/sim/rendering/shadows/enabled=false
--prop:/sim/rendering/shadows/filtering=0
--prop:/sim/rendering/headshake/enabled=true
--prop:/sim/rendering/pilot-model=enabled=false
--prop:/sim/rendering/shader-experimental=false
--prop:/sim/rendering/shader-effects=false
--prop:/sim/rendering/shaders/custom-settings=true
--prop:/sim/rendering/shaders/clouds=0
--prop:/sim/rendering/shaders/generic=0
--prop:/sim/rendering/shaders/landmass=0
--prop:/sim/rendering/shaders/model=0
--prop:/sim/rendering/shaders/contrails=0
--prop:/sim/rendering/shaders/crop=0
--prop:/sim/rendering/shaders/skydome=false
--prop:/sim/rendering/shaders/transition=0
--prop:/sim/rendering/shaders/urban=0
--prop:/sim/rendering/shaders/water=0
--prop:/sim/rendering/shaders/wind-effects=0
--prop:/sim/rendering/shaders/vegetation-effects=0
--prop:/sim/rendering/shaders/forest=0
--prop:/sim/rendering/shaders/lights=0
--prop:/sim/rendering/shaders/quality-level-internal=0
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
--prop:/local-weather/config/distance-to-load-tile-m=10000
--prop:/local-weather/config/distance-to-remove-tile-m=20000
--prop:/local-weather/config/detailed-clouds-flag=false
--prop:/local-weather/config/max-vis-range-m=21000
--prop:/sim/sound/atc/enabled=false
--prop:/sim/sound/atc/external-view/enabled=false
--fog-fastest
--shading-flat
--model-hz=90
--disable-clouds3d
--enable-clouds
--visibility=4000
EOF
}

Get() {
  # This function is a "Code downloader for Git" (tm).
  # It checks if the code has already been cloned, if so, it checksout the right
  # branch and updates it, if not downloaded, then it downloads it.
  local this="${1}"
  local url="${2}"
  local branch="${3}"
  if [ "${download}" = true ]; then
    tell "DEBUG" "Enter Get."
    if [ -d "$(sourceDir "${this}")" ]; then
      tell "INFO" "Updating \"${this}\""
      enterdir "$(sourceDir "${this}")"
      git pull --prune --jobs="${gitJobs}"
      git checkout "${branch}"
      git pull --prune --jobs="${gitJobs}"
    else
      tell "INFO" "Downloading \"${this}\" source code."
      makedir "${sourcecodeDirectory}"
      git clone -b "${branch}" -j "${gitJobs}" "${url}" "$(sourceDir "${this}")"
      if [ "${this}" = "plib" ]; then
        tell "DEBUG" "\"${this}\" detected, doing version stuff."
        enterdir "$(sourceDir "${this}")"
        echo "1.8.6" > version
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
  # Runs either `make` or `make install` for the selected component.
  local thing="${1}"
  local makeCommand="${2}"
  tell "DEBUG" "Enter Make"
  case "${makeCommand}" in
    "compile")
      tell "INFO" "Compiling \"${thing}\""
      if nice -n "${cpuPriority}" ionice -c "${ioPriority}" \
      make --jobs="${compilerJobs}"; then
        tell "INFO" "\"${thing}\" compiled successfully"
      else
        tell "ERROR" "\"${thing}\" failed to compile"
      exit 1
    fi
    ;;
    "install")
      tell "INFO" "Installing \"${thing}\""
      if make install; then
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
        "--fg-aircraft=\${FG_AIRCRAFT}"
      )
      # Creates the "binary" to launch FlightGear
      cat << EOF > "${launcherFile}"
#!/bin/bash

numberCores="\$(nproc)"
export OSG_NUM_DATABASE_THREADS="\${numberCores}"
if [ "\${numberCores}" -gt 1 ]; then
  export OSG_NUM_HTTP_DATABASE_THREADS="\$(expr \${numberCores} / 2)"
else
  export OSG_NUM_HTTP_DATABASE_THREADS="\$(expr \${numberCores} / 2)"
fi
export LD_LIBRARY_PATH="${installDirectory}/lib"
export PATH="${installDirectory}/bin:\$PATH"
export FG_ROOT="${dataDirectory}"
export FG_HOME="${fghomeDirectory}"
export FG_AIRCRAFT="${aircraftDirectory}"
export FG_DOWNLOAD="${downloadsDirectory}"
export FG_TERRASYNC="${terrasyncDirectory}"
${installDirectory}/bin/fgfs ${flightgearArguments[@]} \${@}
EOF
      chmod +x "${launcherFile}" || exit 1
      MakeConfig || exit 1
    fi
  else
    tell "DEBUG" "install=false"
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


DependsCheck() {
  local thing="${1}"
  local -a dependenciesList=("${@:2}")
  if [ "${checkdepends}" = true ]; then
    tell "DEBUG" "Enter DependsCheck"
    tell "INFO" "Checking dependencies for \"${thing}\""
    case "${thing}" in
      "general")
        for dependencyName in "${dependenciesList[@]}"; do
          tell "DEBUG" "Checking if [${dependencyName}] is installed"
          if which "${dependencyName}" 1> /dev/null; then
            tell "DEBUG" "${dependencyName} found. $(which "${dependencyName}")"
          else
            tell "ERROR" "Couldn't find ${dependencyName}"
            exit 1
          fi
        done
        ;;
      *)
        for dependencyName in "${dependenciesList[@]}"; do
          if [ -f "${dependencyName}" ]; then
            tell "INFO" "${dependencyName} was found"
          else
            tell "ERROR"  "${dependencyName} was not found"
            exit 1
          fi
          return 0
        done
        ;;
    esac
  else
    tell "DEBUG" "checkdepends=false"
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
  local -a componentFlags+=( "${commonCMakeFlags[@]}" )
  case "${targetName}" in
    "general")
      DependsCheck "${targetName}" "${generalDependencies[@]}"
      ;;
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


clear
DrawText "Welcome to FlightGearBuilder-NG" # Hi there, neatly.
echo
FullFG # Fades in the FlightGear logo in a very neat way.

# TODO: Do I want to use this?
#declare -A validArguments
#validArguments[""]=""

# Walks though the command line arguments and do stuff.
# Sets script behaviors by setting those variables.
for commandlineArgument in "${commandlineArguments[@]}"; do
  case "${commandlineArgument}" in
    "--help")
      tell "ERROR" "There's no help"
      exit 0
      ;;
    "--download")
      tell "DEBUG" "Download enabled"
      download=true
      shift
      ;;
    "--no-download")
      tell "DEBUG" "Download disabled"
      download=false
      shift
      ;;
    "--check-dependencies")
      tell "DEBUG" "Check dependencies enabled"
      checkdepends=true
      shift
      ;;
    "--no-check-dependencies")
      tell "DEBUG" "Check dependencies disabled"
      checkdepends=false
      shift
      ;;
    "--cmake")
      tell "DEBUG" "CMake enabled"
      cmake=true
      shift
      ;;
    "--no-cmake")
      tell "DEBUG" "CMake disabled"
      cmake=false
      shift
      ;;
    "--compile")
      tell "DEBUG" "Compile enabled"
      compile=true
      shift
      ;;
    "--no-compile")
      tell "DEBUG" "Compile disabled"
      compile=false
      shift
      ;;
    "--install")
      tell "DEBUG" "Install enabled"
      install=true
      shift
      ;;
    "--no-install")
      tell "DEBUG" "Install disabled"
      install=false
      shift
      ;;
  esac
done

#### Show Starter ####
# Checks for general dependencies, `gcc`, `git` and so on.
[[ "$#" -gt 0 ]] && _do "general"

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
