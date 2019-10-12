cmake_minimum_required(VERSION 3.5)

project(qtmongo LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt5 COMPONENTS Widgets REQUIRED)


add_executable(qtmongo
  main.cpp
  mainwindow.cpp
  mainwindow.h
  mainwindow.ui
)

set( INSTALL_DIR "../mongocxx/install")
set( MONGOCXX_LDFLAGS
                -L$INSTALL_DIR/lib
                -lmongocxx-static -lbsoncxx-static
                -lmongoc-static-1.0
                -lz -lsnappy -licuuc -lbson-static-1.0
                -lcrypt32 -lDnsapi -lBcrypt -lSecur32 -lWs2_32 )


target_compile_definitions( qtmongo PRIVATE MONGOCXX_STATIC BSONCXX_STATIC MONGOC_STATIC BSON_STATIC )
target_include_directories( qtmongo PRIVATE
    ${INSTALL_DIR}/include/mongocxx/v_noabi
    ${INSTALL_DIR}/include/bsoncxx/v_noabi
    ${INSTALL_DIR}/include/libmongoc-1.0
    ${INSTALL_DIR}/include/libbson-1.0 )
target_link_directories( qtmongo PRIVATE ${INSTALL_DIR}/lib )
target_link_libraries(qtmongo PRIVATE Qt5::Widgets
    mongocxx-static bsoncxx-static mongoc-static-1.0
    z snappy icuuc bson-static-1.0
    crypt32 Dnsapi Bcrypt Secur32 Ws2_32 )

