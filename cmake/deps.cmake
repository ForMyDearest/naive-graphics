include_guard(GLOBAL)

find_package(Git REQUIRED)
message(STATUS "Updating submodules to latest ...")
execute_process(
        COMMAND "${GIT_EXECUTABLE}" submodule update --init --remote --recursive
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        COMMAND_ERROR_IS_FATAL ANY
)

file(GLOB _dep_scripts CONFIGURE_DEPENDS "${CMAKE_CURRENT_LIST_DIR}/deps/*.cmake")
foreach (_script IN LISTS _dep_scripts)
    message(STATUS "Including dependency: ${_script}")
    include("${_script}")
endforeach ()