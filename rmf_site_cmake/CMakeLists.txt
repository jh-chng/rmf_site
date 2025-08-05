cmake_minimum_required(VERSION 3.10)
project(rmf_site_cmake)

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

# Define the installation directory for the package
set(config_install_dir "${CMAKE_INSTALL_DATADIR}/cmake/rmf_site_cmake")

message(STATUS "Configuring rmf_site_cmake package for installation to ${config_install_dir}")

# Use configure_package_config_file to create the package config file
configure_package_config_file(
  cmake/rmf_site_cmakeConfig.cmake.in
  "${CMAKE_CURRENT_BINARY_DIR}/rmf_site_cmakeConfig.cmake"
  INSTALL_DESTINATION "${config_install_dir}"
  PATH_VARS CMAKE_INSTALL_DATADIR
)

# Install the package configuration file
install(
  FILES
    "${CMAKE_CURRENT_BINARY_DIR}/rmf_site_cmakeConfig.cmake"
  DESTINATION
    "${config_install_dir}"
)

message(STATUS "Installing rmf_site_generation.cmake to ${CMAKE_INSTALL_DATADIR}/cmake/rmf_site_cmake")

# Install the rmf_site_generation.cmake file to the DATADIR
install(
  FILES
    cmake/rmf_site_generation.cmake
  DESTINATION
    "${CMAKE_INSTALL_DATADIR}/cmake/rmf_site_cmake"
)