package oracle.forms.ms;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.Scanner;
import java.util.logging.Level;
import java.util.logging.Logger;

import oracle.forms.ui.VBean;

public class jtcp extends VBean {

    private static String inetAddress = "localhost";
    private static int port = 4444;
    private static Socket socket = null;
    private static PrintWriter printWriter;
    
    public jtcp(){
     super();
    }
     
    public static void setUrl(String url){
        try {
            socket = new Socket(inetAddress, port);
            System.out.println("InetAddress: " + inetAddress);
            System.out.println("Port: " + port);
            
            printWriter = new PrintWriter(socket.getOutputStream(), true); 
            printWriter.println(url);
            socket.close();
            System.out.println("Socket closed");
        } catch (UnknownHostException ex) {
            Logger.getLogger(jtcp.class.getName()).log(Level.SEVERE, null, ex);
        } catch (IOException ex) {
            Logger.getLogger(jtcp.class.getName()).log(Level.SEVERE, null, ex);
        } finally {  
            if( socket != null){
                try {
                    socket.close();
                } catch (IOException ex) {
                    Logger.getLogger(jtcp.class.getName()).log(Level.SEVERE, null, ex);
                } 
            }
        }        
    }
    
    public static void main(String[] args) {
        jtcp jtc = new jtcp();
        jtc.setUrl("http://www.google.nl");
    }
}
