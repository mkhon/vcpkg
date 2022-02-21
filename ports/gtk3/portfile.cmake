set(warning_length 24)
string(LENGTH "${CURRENT_BUILDTREES_DIR}" buildtrees_path_length)
if(buildtrees_path_length GREATER warning_length AND CMAKE_HOST_WIN32)
    message(WARNING "${PORT}'s buildsystem uses very long paths and may fail on your system.\n"
        "We recommend moving vcpkg to a short path such as 'C:\\vcpkg' or using the subst command."
    )
endif()

set(GTK_MAJOR_MINOR 3.24)
set(GTK_PATCH 30)

vcpkg_download_distfile(ARCHIVE
    URLS "https://ftp.gnome.org/pub/gnome/sources/gtk+/${GTK_MAJOR_MINOR}/gtk+-${GTK_MAJOR_MINOR}.${GTK_PATCH}.tar.xz"
    FILENAME "gtk+-${GTK_MAJOR_MINOR}.${GTK_PATCH}.tar.xz"
    SHA512 4164559f3e14501b9f9330a76535ebf5e26961d436f65e65ea609998cb120fcbcc5d9591453a64e1d414248499857288e5758274d03a7f75e9ae76cbf8c68ff9
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        0001-build.patch
        0002-windows-sdk11.patch
        0003-disable-atk-bridge.patch
        winpointer.h.patch
)

vcpkg_find_acquire_program(PKGCONFIG)
get_filename_component(PKGCONFIG_DIR "${PKGCONFIG}" DIRECTORY )
vcpkg_add_to_path("${PKGCONFIG_DIR}") # Post install script runs pkg-config so it needs to be on PATH
vcpkg_add_to_path("${CURRENT_HOST_INSTALLED_DIR}/tools/glib/")
vcpkg_add_to_path("${CURRENT_HOST_INSTALLED_DIR}/tools/gdk-pixbuf")
vcpkg_add_to_path("${CURRENT_HOST_INSTALLED_DIR}/tools/gettext/bin")

if("introspection" IN_LIST FEATURES)
    if(VCPKG_TARGET_IS_WINDOWS AND VCPKG_LIBRARY_LINKAGE STREQUAL "static")
        message(FATAL_ERROR "Feature introspection currently only supports dynamic build.")
    endif()
    list(APPEND OPTIONS_DEBUG -Dintrospection=false)
    list(APPEND OPTIONS_RELEASE -Dintrospection=true)
else()
    list(APPEND OPTIONS -Dintrospection=false)
endif()

if(CMAKE_HOST_WIN32 AND VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    set(GIR_TOOL_DIR ${CURRENT_INSTALLED_DIR})
else()
    set(GIR_TOOL_DIR ${CURRENT_HOST_INSTALLED_DIR})
endif()

vcpkg_configure_meson(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${OPTIONS}
        -Dwayland_backend=false
        -Ddemos=false
        -Dexamples=false
        -Dtests=false
        -Dgtk_doc=false
        -Dman=false
        -Dxinerama=no               # Enable support for the X11 Xinerama extension
        -Dcloudproviders=false      # Enable the cloudproviders support
        -Dprofiler=false            # include tracing support for sysprof
        -Dtracker3=false            # Enable Tracker3 filechooser search
        -Dcolord=no                 # Build colord support for the CUPS printing backend
    OPTIONS_DEBUG
        ${OPTIONS_DEBUG}
    OPTIONS_RELEASE
        ${OPTIONS_RELEASE}
    ADDITIONAL_NATIVE_BINARIES
        glib-genmarshal='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/glib-genmarshal'
        glib-mkenums='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/glib-mkenums'
        glib-compile-resources='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/glib-compile-resources${VCPKG_HOST_EXECUTABLE_SUFFIX}'
        gdbus-codegen='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/gdbus-codegen'
        glib-compile-schemas='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/glib-compile-schemas${VCPKG_HOST_EXECUTABLE_SUFFIX}'
        g-ir-compiler='${CURRENT_HOST_INSTALLED_DIR}/tools/gobject-introspection/g-ir-compiler${VCPKG_HOST_EXECUTABLE_SUFFIX}'
        g-ir-scanner='${GIR_TOOL_DIR}/tools/gobject-introspection/g-ir-scanner'
    ADDITIONAL_CROSS_BINARIES
        glib-genmarshal='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/glib-genmarshal'
        glib-mkenums='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/glib-mkenums'
        glib-compile-resources='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/glib-compile-resources${VCPKG_HOST_EXECUTABLE_SUFFIX}'
        gdbus-codegen='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/gdbus-codegen'
        glib-compile-schemas='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/glib-compile-schemas${VCPKG_HOST_EXECUTABLE_SUFFIX}'
        g-ir-compiler='${CURRENT_HOST_INSTALLED_DIR}/tools/gobject-introspection/g-ir-compiler${VCPKG_HOST_EXECUTABLE_SUFFIX}'
        g-ir-scanner='${GIR_TOOL_DIR}/tools/gobject-introspection/g-ir-scanner'
)

vcpkg_install_meson(ADD_BIN_TO_PATH)

vcpkg_copy_pdbs()

vcpkg_fixup_pkgconfig()

file(INSTALL "${SOURCE_PATH}/COPYING" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

set(GTK_TOOLS
    gtk-builder-tool
    gtk-encode-symbolic-svg
    gtk-launch
    gtk-query-immodules-3.0
    gtk-query-settings
    gtk-update-icon-cache
)
vcpkg_copy_tools(TOOL_NAMES ${GTK_TOOLS} AUTO_CLEAN)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/etc")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()
