cmake_minimum_required(VERSION 3.14)

add_library(camera_engine SHARED
  "camera_engine.cpp"
)

target_include_directories(camera_engine PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_compile_features(camera_engine PUBLIC cxx_std_17)
target_compile_definitions(camera_engine PRIVATE "NOMINMAX")

set_target_properties(camera_engine PROPERTIES
  OUTPUT_NAME "camera_engine"
)
