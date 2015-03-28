package oracle.forms.ms;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class jdbcCreateTable {
    public jdbcCreateTable() {
    }

      public static void main(String[] args) throws Exception {

        Class.forName("oracle.jdbc.driver.OracleDriver");

        String url = "jdbc:oracle:thin:@localhost:1521:xe";
        String username = "hr";
        String password = "hr";

        String sql = "CREATE TABLE books (id NUMBER(11), title VARCHAR2(64))";
        Connection connection = DriverManager.getConnection(url, username, password);
        Statement statement = connection.createStatement();
        statement.execute(sql);
        connection.close();
      }
    }