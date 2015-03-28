
CREATE OR REPLACE AND RESOLVE JAVA SOURCE NAMED base64 AS
package base64;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.IOException;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import oracle.sql.BLOB;
import oracle.sql.CLOB;

import sun.misc.BASE64Decoder;
import sun.misc.BASE64Encoder;


public class base64 {

    public static CLOB blobToBase64 ( BLOB blobCol){
        try {
            BASE64Encoder b64ec = new BASE64Encoder();
            
            Connection con = DriverManager.getConnection("jdbc:default:connection:");
            CLOB newClob = oracle.sql.CLOB.createTemporary(con, true, oracle.sql.CLOB.DURATION_SESSION);

             
            
            int bufSize = 1024*1024*1;
             
            final BufferedInputStream in = new BufferedInputStream(blobCol.getBinaryStream(), bufSize * 2);        
            final BufferedOutputStream out = new BufferedOutputStream(newClob.setAsciiStream(0L), bufSize);
             
            b64ec.encode(in, out);
            out.flush();
            out.close();            
            return newClob;
            } catch (SQLException e) {
            // TODO
        } catch (IOException e) {
            // TODO
        }
        return null;
    }

    public static BLOB base64ToBlob ( CLOB clobCol){
        try {
            BASE64Decoder b64dc = new BASE64Decoder();
           
            Connection con = DriverManager.getConnection("jdbc:default:connection:");
            BLOB newBlob = oracle.sql.BLOB.createTemporary(con, true, oracle.sql.BLOB.DURATION_SESSION);
         
            b64dc.decodeBuffer(clobCol.getAsciiStream(), newBlob.getBinaryOutputStream());
            int bufSize = 1024*1024*1;
             
            final BufferedInputStream in = new BufferedInputStream(clobCol.getAsciiStream(), bufSize * 2);        
            final BufferedOutputStream out = new BufferedOutputStream(newBlob.setBinaryStream(0L), bufSize);
             
            b64dc.decodeBuffer(in, out);
            out.flush();
            out.close();            
           
            return newBlob;
           
        } catch (SQLException e) {
            // TODO
        } catch (IOException e) {
            // TODO
        }
        return null;
    }  
}
/

create or replace function base64decode(clobCol in CLOB) return BLOB as language java name 'base64.base64.base64ToBlob(oracle.sql.CLOB) return oracle.sql.BLOB'
/
create or replace function base64encode(blobCol in BLOB) return CLOB as language java name 'base64.base64.blobToBase64(oracle.sql.BLOB) return oracle.sql.CLOB'
/