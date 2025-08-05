# Set the minimum version of CMake required for this project.
cmake_minimum_required(VERSION 3.12)

# Define the project name.
project(rmf_site_generate
  VERSION 0.1.0
  LANGUAGES CXX
)

# This module is needed for the cmake_parse_arguments function.
include(CMakeParseArguments)

# ==============================================================================
# Function: rmf_site_generate
#
# Generates a world file and a navigation graph directory from an RMF building.yaml.
#
# Arguments:
#   INPUT           <path_to_yaml_file>   (REQUIRED) Input path to a single RMF building input file (.yaml).
#   OUTPUT_WORLD    <path_to_world_file>  (REQUIRED) Output path  the output world file (.world).
#   OUTPUT_NAV_DIR  <path_to_nav_dir>     (REQUIRED) Output path to the nav_graph directory. 
#                                                    Generated nav_graphs will be placed inside.
#
#   DEPENDS         <list_of_dependencies> (OPTIONAL) List of files or targets that this generation depends on.
# Example:
#   rmf_site_generate(
#     INPUT ${path}
#     OUTPUT_WORLD ${CMAKE_CURRENT_BINARY_DIR}/maps/${world_name}.world
#     OUTPUT_NAV_DIR ${CMAKE_CURRENT_BINARY_DIR}/maps/${WORLD_NAME}/nav_graphs
#   )
# ==============================================================================
function(rmf_site_generate)
  # Define expected arguments for cmake_parse_arguments
  set(options "")
  set(oneValueArgs INPUT OUTPUT_WORLD OUTPUT_NAV_DIR)
  set(multiValueArgs DEPENDS)

  # Parse the input arguments from the function call
  cmake_parse_arguments(RMF_SITE_GEN "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # --- Argument Validation ---
  if(NOT RMF_SITE_GEN_INPUT)
    message(FATAL_ERROR "rmf_site_generate: INPUT argument is required.")
  endif()
  if(NOT RMF_SITE_GEN_OUTPUT_WORLD)
    message(FATAL_ERROR "rmf_site_generate: OUTPUT_WORLD argument is required.")
  endif()
  if(NOT RMF_SITE_GEN_OUTPUT_NAV_DIR)
    message(FATAL_ERROR "rmf_site_generate: OUTPUT_NAV_DIR argument is required.")
  endif()

  # Define a unique target name for this generation task
  get_filename_component(input_basename "${RMF_SITE_GEN_INPUT}" NAME_WE)
  set(target_name "generate_${input_basename}_site")

  # Ensure the output directories exist before running the command
  get_filename_component(output_world_dir "${RMF_SITE_GEN_OUTPUT_WORLD}" DIRECTORY)
  file(MAKE_DIRECTORY "${output_world_dir}")
  file(MAKE_DIRECTORY "${RMF_SITE_GEN_OUTPUT_NAV_DIR}")

  # Add a custom command to run rmf_site_editor.
  # This command now uses a .yaml input and a .world output.
  add_custom_command(
    OUTPUT "${RMF_SITE_GEN_OUTPUT_WORLD}" "${RMF_SITE_GEN_OUTPUT_NAV_DIR}"
    COMMAND rmf_site_editor
            "${RMF_SITE_GEN_INPUT}"
            --export-world "${RMF_SITE_GEN_OUTPUT_WORLD}"
            --export-nav "${RMF_SITE_GEN_OUTPUT_NAV_DIR}"
    DEPENDS "${RMF_SITE_GEN_INPUT}" ${RMF_SITE_GEN_DEPENDS}
    COMMENT "Generating world and nav graphs from ${input_basename}.yaml"
    VERBATIM
  )
endfunction()

# ==============================================================================
# Function: rmf_site_generate_map_package
#
# Generates a complete RMF map package from a site input file.
# The package includes the world file and a navigation graph directory.
#
# Arguments:
#   INPUT               <path_to_rmf_building_yaml_files>  (REQUIRED) Input path to a directory that has building.yamls inside.
#
#   DEPENDS             <list_of_dependencies> (OPTIONAL) List of files or targets that this generation depends on.
#
# Example:
#   rmf_site_generate_map_package(
#      INPUT_MAP_DIR maps/
#   )
# ==============================================================================
function(rmf_site_generate_map_package)
  # Define expected arguments for cmake_parse_arguments
  set(options "")
  set(oneValueArgs INPUT OUTPUT_PACKAGE_DIR PACKAGE_NAME)
  set(multiValueArgs DEPENDS)

  # Parse the input arguments from the function call
  cmake_parse_arguments(RMF_SITE_PKG_GEN "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # --- Argument Validation ---
  if(NOT RMF_SITE_PKG_GEN_INPUT)
    message(FATAL_ERROR "rmf_site_generate_map_package: INPUT argument is required.")
  endif()
  if(NOT RMF_SITE_PKG_GEN_OUTPUT_PACKAGE_DIR)
    message(FATAL_ERROR "rmf_site_generate_map_package: OUTPUT_PACKAGE_DIR argument is required.")
  endif()
  if(NOT RMF_SITE_PKG_GEN_PACKAGE_NAME)
    message(FATAL_ERROR "rmf_site_generate_map_package: PACKAGE_NAME argument is required.")
  endif()

  # Define the output paths within the package directory
  set(output_world_file "${RMF_SITE_PKG_GEN_OUTPUT_PACKAGE_DIR}/worlds/${RMF_SITE_PKG_GEN_PACKAGE_NAME}.sdf")
  set(output_nav_dir "${RMF_SITE_PKG_GEN_OUTPUT_PACKAGE_DIR}/nav_graphs")

  # Define a unique target name for this generation task
  set(target_name "generate_${RMF_SITE_PKG_GEN_PACKAGE_NAME}_package")

  # Ensure the output directories exist
  file(MAKE_DIRECTORY "${RMF_SITE_PKG_GEN_OUTPUT_PACKAGE_DIR}/worlds")
  file(MAKE_DIRECTORY "${output_nav_dir}")

  file(GLOB_RECURSE site_paths "*.building.yaml")

  foreach(path ${site_paths})

    # Get the output world name
    string(REGEX REPLACE "\\.[^.]*\.[^.]*$" "" no_extension_path ${path})
    string(REGEX MATCH "[^\/]+$" world_name  ${no_extension_path})
    
    rmf_site_generate(
        INPUT ${path}
        OUTPUT_WORLD ${CMAKE_CURRENT_BINARY_DIR}/maps/${world_name}.world
        OUTPUT_NAV_DIR ${CMAKE_CURRENT_BINARY_DIR}/maps/${WORLD_NAME}/nav_graphs
    )
  endforeach()  # Add a custom target to represent the generation of the entire package

endfunction()

# ==============================================================================
# Example Usage
#
# Create an 'assets' directory in your project root and place your .rmf file there.
# mkdir -p assets
# touch assets/my_building.rmf
#
# Then run:
# cmake -S . -B build
# cmake --build build --target all
# ==============================================================================

# Example of generating a simple site from an RMF file
rmf_site_generate(
  INPUT "${CMAKE_CURRENT_SOURCE_DIR}/assets/my_building.rmf"
  OUTPUT_WORLD "${CMAKE_CURRENT_BINARY_DIR}/simple_site/my_building.sdf"
  OUTPUT_NAV_DIR "${CMAKE_CURRENT_BINARY_DIR}/simple_site/nav_graphs"
)

# Example of generating a full map package
rmf_site_generate_map_package(
  INPUT "${CMAKE_CURRENT_SOURCE_DIR}/assets/my_building.rmf"
  OUTPUT_PACKAGE_DIR "${CMAKE_CURRENT_BINARY_DIR}/my_building_map_package"
  PACKAGE_NAME "my_building_map"
)