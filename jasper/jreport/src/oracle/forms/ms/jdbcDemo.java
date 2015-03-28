package oracle.forms.ms;

import java.io.Serializable;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLData;
import java.sql.SQLException;
import java.sql.SQLInput;
import java.sql.SQLOutput;


public class jdbcDemo {
    public jdbcDemo() {
    }

 
  public static Connection getConnection() throws Exception {
    String driver = "oracle.jdbc.driver.OracleDriver";
    String url = "jdbc:oracle:thin:@localhost:1521:xe";
    String username = "hr";
    String password = "hr";
    Class.forName(driver); // load Oracle driver
    return DriverManager.getConnection(url, username, password);
  }

  public static void main(String[] args) {
    String id = "001";
    String isbn = "1234567890";
    String title = "java demo";
    String author = "java2s";
    int edition = 1;

    Connection conn = null;
    PreparedStatement pstmt = null;
    try {
      conn = getConnection();
      String insert = "insert into book_table values(?, BOOK(?, ?, ?, ?))";
      pstmt = conn.prepareStatement(insert);
      pstmt.setString(1, id);
      pstmt.setString(2, isbn);
      pstmt.setString(3, title);
      pstmt.setString(4, author);
      pstmt.setInt(5, edition);
      pstmt.executeUpdate();
    } catch (Exception e) {
      e.printStackTrace();
      System.exit(1);
    } finally {
      try {
        pstmt.close();
        conn.close();
      } catch (SQLException e) {
        e.printStackTrace();
      }
    }
  }
    /**
     * A class to hold a copy of "BOOK" data type
     */
    class Book implements SQLData, Serializable {

      public static final String SQL_TYPE_NAME = "BOOK";

      public String isbn;

      public String title;

      public String author;

      public int edition;

      public Book() {
      }

      public Book(String isbn, String title, String author, int edition) {
        this.isbn = isbn;
        this.title = title;
        this.author = author;
        this.edition = edition;
      }

      // retrieves the fully qualified name of the SQL
      // user-defined type that this object represents.
      public String getSQLTypeName() {
        return SQL_TYPE_NAME;
      }

      // populates this object with data it reads from stream
      public void readSQL(SQLInput stream, String sqlType) throws SQLException {
        this.isbn = stream.readString();
        this.title = stream.readString();
        this.author = stream.readString();
        this.edition = stream.readInt();
      }

      // writes this object to stream
      public void writeSQL(SQLOutput stream) throws SQLException {
        stream.writeString(this.isbn);
        stream.writeString(this.title);
        stream.writeString(this.author);
        stream.writeInt(this.edition);
      }

      public void print() {
        System.out.println("isbn=" + isbn);
        System.out.println("title=" + title);
        System.out.println("author=" + author);
        System.out.println("edition=" + edition);
      }
    }
}