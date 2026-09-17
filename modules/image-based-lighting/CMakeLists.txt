set(TARGET_NAME image-based-lighting)

find_package (glfw3 CONFIG REQUIRED)

add_executable(${TARGET_NAME} main.cpp)
set_target_properties(${TARGET_NAME} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${TARGET_NAME}")

target_link_libraries(${TARGET_NAME} slang-rhi glfw)

add_custom_command(TARGET "${TARGET_NAME}" POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy -t "$<TARGET_FILE_DIR:${TARGET_NAME}>"
        $<TARGET_RUNTIME_DLLS:${TARGET_NAME}>
        COMMAND_EXPAND_LISTS
        COMMENT "Copying runtime DLLs for ${TARGET_NAME}"
        VERBATIM
)

target_copy_assets(${TARGET_NAME} circle.slang ocean.slang shader-toy.slang)
#target_link_libraries(image-based-lighting Vulkan::Vulkan glfw glm::glm slang::slang tinyobjloader::tinyobjloader)
#target_compile_definitions(image-based-lighting PUBLIC VULKAN_HPP_DISPATCH_LOADER_DYNAMIC=1 VULKAN_HPP_NO_STRUCT_CONSTRUCTORS=1)
#target_include_directories(image-based-lighting PRIVATE ${Stb_INCLUDE_DIR})