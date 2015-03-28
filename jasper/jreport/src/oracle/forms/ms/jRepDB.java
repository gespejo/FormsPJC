package oracle.forms.ms;

import java.net.MalformedURLException;
import java.net.URL;

import java.sql.Connection;
import java.sql.DriverManager;

import java.util.HashMap;
import java.util.Map;

import javax.swing.JFrame;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperFillManager;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.JasperReport;
import net.sf.jasperreports.engine.util.JRLoader;
import net.sf.jasperreports.swing.JRViewer;

import oracle.forms.ui.VBean;


/**
 * This class opens a JRViewer inside Oracle Forms.
 * <hr>
 * Tis example may be used and altered if needed.
 * 
 * Be aware of the license which comes with the use of Jasper Reports.
 * 
 * @Author Mark Striekwold
 * @Version 1
 */

public class jRepDB extends VBean{
    private static StringBuffer sb = new StringBuffer(); 
    private static JasperReport jasperReport;
    private static JasperPrint  jasperPrint;
    private static Connection   conn;
    private static String       report;
    private static URL          repURL;
    private Map <String, Object> parameters = new HashMap<String, Object>();
    private JRViewer jr;
    
     /**
      * setConnection
      * setup a connection to the database
      */
    public void setConnection(String value){
        String s = value.toString();
              String s1=null,s2=null,s3=null;
              int i1, i2,i3;
              int iPos = s.indexOf("|");
              int iPos2 = s.indexOf("|",iPos+1);
              if(iPos > -1) {
                  try {
                      s1 = s.substring(0, iPos) ;
                      s2 = s.substring(iPos+1, iPos2) ;
                      s3 = s.substring(iPos2+1);
        }
            catch(Exception ex){
                  System.out.println("incorrect values: "+s);}
        }
        setConn(s1, s2, s3);
    }

    /**
     * setConn     
     * set up a connection to the database
     */
    private void setConn(String db, String username, String passwd){
        try  {        
             // username
             // password
             DriverManager.registerDriver(new oracle.jdbc.OracleDriver());
             conn = DriverManager.getConnection(
             "jdbc:oracle:thin:@localhost:1521:"+db,
             username,  // username
             passwd   // password
             );
             
             // code the check if the connection to the database works
             //Statement stmt = conn.createStatement ();
             //  ResultSet rset =
             //       stmt.executeQuery("select BANNER from SYS.V_$VERSION");
             //  while (rset.next()) {
             //       System.out.println (rset.getString(1));
             //  }
         }  
         catch (Exception e)  {  
           System.out.println(e);  
         }  
    }
    
    /*
     * setParameters
     * set the parameter for the report
     */
    public void setParameters(String value){
        String s = value.toString();
              String s1=null,s2=null;
              int i1, i2;
              int iPos = s.indexOf("|");
              if(iPos > -1) {
                  try {
                      s1 = s.substring(0,iPos) ;
                      s2 = s.substring(iPos+1) ;
        }
                  catch(Exception ex){
                  System.out.println("setConfig() incorrect values: "+s);}
        }
        parameters.put(s1, s2);
    }
    
    /*
     * setReport
     * set the url which contains the report
     */
    public void setReport(String repString){
        try {
            repURL = new URL (repString);
        } catch (MalformedURLException e) {
            System.out.println(e);  
        }
    }
    
    /*
     * showReport
     * display the report
     */
    public void showReport()
    { 
        try {
            jasperReport = (JasperReport) JRLoader.loadObject(repURL);
            jasperPrint  = JasperFillManager.fillReport(jasperReport, parameters, conn);
            jr = new JRViewer(jasperPrint);
            add(jr);
        } catch (JRException e) {
            System.out.println(e);  
        }

    }

    /*
     * dropReport
     * drop the current report so we can make a new one
     */
    public void dropReport()
    { 
        this.remove(jr);
    }


    public jRepDB() {
    }
    
    /*
     * main method
     */
    public static void main(String[] args) {
        JFrame frame  = new JFrame("JReport");
        jRepDB main = new jRepDB();
        // XE is my tes database
        main.setConnection( "XE|hr|hr");      
        // winxp is my test machine
        main.setReport("http://winxp:8889/forms/java/coffee.jasper");
        // which do you want to display
        main.setParameters("P_LAST_NAME|De Haan");
        main.showReport();
        // Add the control panel and desktop (JDesktopPane) to the application content pane.    
        frame.getContentPane().add(main);
        frame.pack();
        frame.setSize(800, 600); // adjust the frame size using specific dimensions.
        frame.setVisible(true); // show the frame.
    }

}
