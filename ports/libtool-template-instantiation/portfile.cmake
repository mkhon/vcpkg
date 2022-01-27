vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO mkhon/libtool-template-instantiation
    HEAD_REF master
)

vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    USE_WRAPPERS
    OPTIONS
        lt_cv_deplibs_check_method=pass_all
        LDFLAGS=-no-undefined
)
vcpkg_install_make()
