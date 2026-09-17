# ---------------------------------------------------------------------------
# target_copy_assets(<target> [<asset>...])
#
# Copies asset files (or whole directories) from the repository assets/ folder
# into the directory of the built executable, mirroring their relative path.
# A model and its textures live in one shared folder, so passing that folder
# copies them together:
#
#   assets/plant_on_table/
#     -> .build/<preset>/plant_on_table/
#
# Paths are resolved against ${CMAKE_SOURCE_DIR}/assets (absolute paths also
# work). The copy runs as part of the build and only re-runs when an asset
# actually changed; new files inside a passed directory are picked up as well.
# ---------------------------------------------------------------------------
function(target_copy_assets TARGET)
    if (NOT TARGET "${TARGET}")
        message(FATAL_ERROR "target_copy_assets: '${TARGET}' is not a defined target")
    endif ()
    if (TARGET "${TARGET}_CopyAssets")
        message(FATAL_ERROR "target_copy_assets: assets for '${TARGET}' are already registered")
    endif ()
    if (NOT ARGN)
        message(FATAL_ERROR "target_copy_assets: no assets given for '${TARGET}'")
    endif ()

    set(assets_root "${CMAKE_SOURCE_DIR}/assets")

    set(srcs)
    set(dst_dirs)
    set(commands)

    foreach (asset IN LISTS ARGN)
        file(TO_CMAKE_PATH "${asset}" asset)

        if (IS_ABSOLUTE "${asset}")
            set(src "${asset}")
        else ()
            set(src "${assets_root}/${asset}")
        endif ()
        cmake_path(SET src NORMALIZE "${src}")

        if (NOT EXISTS "${src}")
            message(FATAL_ERROR
                    "target_copy_assets(${TARGET}): asset does not exist: '${src}'\n"
                    "(paths are resolved against ${assets_root})"
            )
        endif ()

        # Layout next to the exe mirrors the path relative to assets/,
        # keeping a model and its textures in their shared folder.
        cmake_path(RELATIVE_PATH src BASE_DIRECTORY "${assets_root}" OUTPUT_VARIABLE rel)
        if (rel MATCHES "^\\.\\.(/|$)")
            message(FATAL_ERROR "target_copy_assets(${TARGET}): asset '${src}' is outside ${assets_root}")
        endif ()
        set(dst_rel "${rel}")

        # Destination directory (next to the exe, per-config for multi-config
        # generators through the generator expression), derived from dst_rel.
        cmake_path(GET dst_rel PARENT_PATH dst_parent)
        set(dst_dir "$<TARGET_FILE_DIR:${TARGET}>")
        if (dst_parent)
            string(APPEND dst_dir "/${dst_parent}")
        endif ()
        list(FIND dst_dirs "${dst_dir}" idx)
        if (idx EQUAL -1)
            list(APPEND dst_dirs "${dst_dir}")
        endif ()

        if (IS_DIRECTORY "${src}")
            # Depend on the files inside so content edits re-trigger the copy.
            file(GLOB_RECURSE dir_srcs CONFIGURE_DEPENDS "${src}/*")
            list(APPEND srcs ${dir_srcs})
            list(APPEND commands
                    COMMAND "${CMAKE_COMMAND}" -E copy_directory_if_different
                    "${src}" "$<TARGET_FILE_DIR:${TARGET}>/${dst_rel}")
        else ()
            list(APPEND srcs "${src}")
            list(APPEND commands
                    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                    "${src}" "$<TARGET_FILE_DIR:${TARGET}>/${dst_rel}")
        endif ()
    endforeach ()

    set(mkdir_command)
    if (dst_dirs)
        set(mkdir_command COMMAND "${CMAKE_COMMAND}" -E make_directory ${dst_dirs})
    endif ()

    string(REPLACE ";" ", " asset_names "${ARGN}")
    set(stamp "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.assets.stamp")
    add_custom_command(
            OUTPUT "${stamp}"
            ${mkdir_command}
            ${commands}
            COMMAND "${CMAKE_COMMAND}" -E touch "${stamp}"
            DEPENDS ${srcs}
            COMMENT "Copying assets for ${TARGET}: ${asset_names}"
            VERBATIM
    )
    add_custom_target("${TARGET}_CopyAssets" DEPENDS "${stamp}")
    add_dependencies("${TARGET}" "${TARGET}_CopyAssets")

    # Run from wherever the exe lands when debugging from an IDE.
    set_target_properties("${TARGET}" PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "$<TARGET_FILE_DIR:${TARGET}>")
endfunction()

add_subdirectory(image-based-lighting)