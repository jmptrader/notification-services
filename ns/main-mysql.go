package main

import (
	"fmt"
	_ "github.com/go-sql-driver/mysql"
	"database/sql"
)

/*
create database pubsubsql;
create user pubsubsql identified by 'pubsubsql';
GRANT ALL PRIVILEGES ON *.* TO 'pubsubsql'@'%' WITH GRANT OPTION;
 */
func main() {
	conn, err := sql.Open("mysql", "pubsubsql:pubsubsql@/pubsubsql")
	if nil != err {
		fmt.Println(err)
		return
	}
	defer conn.Close()

	row := conn.QueryRow("select ? from dual", 123)
	n := 0
	err = row.Scan(&n)
	if nil != err {
		fmt.Println(err)
		return
	}

	fmt.Println(n)
	fmt.Println("Done.")
}
