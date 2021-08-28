cmake_minimum_required(VERSION 3.7)

project( Main )

add_compile_options(-W -Wall -Wno-missing-field-initializers)

set  (SOURCES "main.cpp")

source_group("src" FILES ${SOURCES})

add_executable(server
	${SOURCES}
	)

target_include_directories ( ws2811 PUBLIC "${PROJECT_SOURCE_DIR}/../rpi_ws281x")
target_link_libraries(server PUBLIC LuaLib )
target_link_libraries(server PUBLIC ws2811 )

target_link_libraries(server PUBLIC httplib::httplib)

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
target_link_libraries(server PRIVATE Threads::Threads)