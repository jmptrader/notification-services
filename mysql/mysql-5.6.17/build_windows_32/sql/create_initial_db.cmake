# Copyright (c) 2009, 2013, Oracle and/or its affiliates. All rights reserved.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA 

# This script creates initial database for packaging on Windows
SET(CMAKE_SOURCE_DIR "C:/home/workspace/go/src/github.com/notification-services/mysql/windows/mysql-5.6.17")
SET(CMAKE_CURRENT_BINARY_DIR "C:/home/workspace/go/src/github.com/notification-services/mysql/windows/mysql-5.6.17/build_windows_32/sql")
SET(MYSQLD_EXECUTABLE "C:/home/workspace/go/src/github.com/notification-services/mysql/windows/mysql-5.6.17/build_windows_32/sql/$(Configuration)/mysqld.exe")
SET(CMAKE_CFG_INTDIR "$(Configuration)")

SET(WITH_SSL_PATH "")
SET(CRYPTO_LIBRARY "")
SET(OPENSSL_LIBRARY "")

SET(WIN32 "1")

# Force Visual Studio to output to stdout
IF(ENV{VS_UNICODE_OUTPUT})
 SET ($ENV{VS_UNICODE_OUTPUT})
ENDIF()
IF(CMAKE_CFG_INTDIR AND CONFIG)
  #Resolve build configuration variables
  STRING(REPLACE "${CMAKE_CFG_INTDIR}" ${CONFIG} MYSQLD_EXECUTABLE 
    "${MYSQLD_EXECUTABLE}")
ENDIF()

# Create bootstrapper SQL script
FILE(WRITE bootstrap.sql "use mysql;\n" )
FOREACH(FILENAME mysql_system_tables.sql mysql_system_tables_data.sql)
   FILE(STRINGS ${CMAKE_SOURCE_DIR}/scripts/${FILENAME} CONTENTS)
   FOREACH(STR ${CONTENTS})
    IF(NOT STR MATCHES "@current_hostname")
      FILE(APPEND bootstrap.sql "${STR}\n")
    ENDIF()
  ENDFOREACH()
ENDFOREACH()
FILE(READ ${CMAKE_SOURCE_DIR}/scripts/fill_help_tables.sql CONTENTS)
FILE(APPEND bootstrap.sql "${CONTENTS}")


FILE(REMOVE_RECURSE mysql performance_schema)
FILE(REMOVE ibdata1 ib_logfile0 ib_logfile1)

MAKE_DIRECTORY(mysql)
IF(WIN32)
  SET(CONSOLE --console)
ENDIF()

SET(BOOTSTRAP_COMMAND 
  ${MYSQLD_EXECUTABLE} 
  --no-defaults 
  ${CONSOLE}
  --bootstrap
  --lc-messages-dir=${CMAKE_CURRENT_BINARY_DIR}/share
  --basedir=.
  --datadir=.
  --default-storage-engine=MyISAM
  --default-tmp-storage-engine=MyISAM
  --loose-skip-ndbcluster
  --max_allowed_packet=8M
  --net_buffer_length=16K
)

GET_FILENAME_COMPONENT(CWD . ABSOLUTE)

IF(WITH_SSL_PATH AND HAVE_CRYPTO_DLL AND HAVE_OPENSSL_DLL)
  GET_FILENAME_COMPONENT(MYSQLD_DIR "${MYSQLD_EXECUTABLE}" PATH)
  GET_FILENAME_COMPONENT(CRYPTO_NAME "${CRYPTO_LIBRARY}" NAME_WE)
  GET_FILENAME_COMPONENT(OPENSSL_NAME "${OPENSSL_LIBRARY}" NAME_WE)
  CONFIGURE_FILE("${WITH_SSL_PATH}/bin/${CRYPTO_NAME}.dll"
                 "${MYSQLD_DIR}/${CRYPTO_NAME}.dll" COPYONLY)
  CONFIGURE_FILE("${WITH_SSL_PATH}/bin/${OPENSSL_NAME}.dll"
                 "${MYSQLD_DIR}/${OPENSSL_NAME}.dll" COPYONLY)
ENDIF()

EXECUTE_PROCESS(
  COMMAND "C:/Program Files (x86)/CMake 2.8/bin/cmake.exe" -E echo Executing ${BOOTSTRAP_COMMAND}
)
EXECUTE_PROCESS (
  COMMAND "C:/Program Files (x86)/CMake 2.8/bin/cmake.exe" -E
  echo input file bootstrap.sql, current directory ${CWD}
)
EXECUTE_PROCESS (  
  COMMAND ${BOOTSTRAP_COMMAND}
  INPUT_FILE bootstrap.sql
  OUTPUT_VARIABLE OUT
  ERROR_VARIABLE ERR
  RESULT_VARIABLE RESULT
 )

IF(NOT RESULT EQUAL 0)
  MESSAGE(FATAL_ERROR "Could not create initial database \n ${OUT} \n ${ERR}")
ENDIF()
 
EXECUTE_PROCESS (  
  COMMAND "C:/Program Files (x86)/CMake 2.8/bin/cmake.exe" -E touch ${CMAKE_CURRENT_BINARY_DIR}/initdb.dep
)
