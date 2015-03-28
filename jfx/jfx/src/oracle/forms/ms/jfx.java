package oracle.forms.ms;

import com.sun.javafx.application.PlatformImpl;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import java.io.IOException;
import java.io.PrintWriter;

import java.net.MalformedURLException;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.URL;

import java.util.Scanner;
import java.util.logging.Level;
import java.util.logging.Logger;

import javafx.application.Platform;

import javafx.collections.ObservableList;

import javafx.embed.swing.JFXPanel;

import javafx.scene.Group;
import javafx.scene.Node;
import javafx.scene.Scene;
import javafx.scene.web.WebEngine;
import javafx.scene.web.WebView;

import javafx.stage.Stage;

import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.SwingUtilities;

import oracle.forms.ui.VBean;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.Scanner;
import java.util.logging.Level;
import java.util.logging.Logger;
public class jfx extends VBean {  
    private WebView browser;  
    private JFXPanel jfxPanel;  
    private WebEngine webEngine; 
    private Scene scene;
    private Group root;
    private int port=4444;
    private ServerSocket serverSocket;
    private Socket socket = null;
    private Scanner scanner;
    
    public jfx() {
    
    }
    
    /** 
     * createScene 
     * 
     * Note: Key is that Scene needs to be created and run on "FX user thread" 
     *       NOT on the AWT-EventQueue Thread 
     * 
     */  
    private void createScene() {  
        PlatformImpl.startup(new Runnable() {  
            @Override
            public void run() {  
                root = new Group();  
                scene = new Scene(root,1024,768);//,80,20); 
                 
                // Set up the embedded browser:
                browser = new WebView();
                browser.setMinSize(1008, 700);
                browser.autosize();

                webEngine = browser.getEngine();
                
                ObservableList<Node> children = root.getChildren();
                children.add(browser);                     
                jfxPanel.setSize(1024, 768); 
                jfxPanel.setScene(scene);  
            }  
        });  
    }
      
    public void createJfx(){  
        SwingUtilities.invokeLater(new Runnable() {  
            @Override
            public void run() {  
                jfxPanel = new JFXPanel();  
                createScene();  
                loadUrl();
                setLayout(new BorderLayout());  
                add(jfxPanel, BorderLayout.CENTER);  
            }  
        });          
    }  

    public void loadUrl(){
        System.out.println("loadUrl");
        PlatformImpl.runLater(new Runnable() {  
            @Override
            public void run() {  
                try {
                    serverSocket = new ServerSocket(4444);
                
                    socket = serverSocket.accept();
                    
                    Scanner scanner = new Scanner(socket.getInputStream());
    
                    String line = scanner.nextLine();
                    System.out.println(line);
                    webEngine.load(line);
                    serverSocket.close();
                    System.out.println("Socket jfx closed");
                } catch (IOException ex) {
                    Logger.getLogger(jfx.class.getName()).log(Level.SEVERE, null, ex);
                } finally {
                     if (socket != null) {
                        try {
                            socket.close();
                        } catch (IOException ex) {
                            Logger.getLogger(jfx.class.getName()).log(Level.SEVERE, null, ex);
                        }
                    }
                }
            }  
        });
    }
  
    public static void main(String ...args){  
        // Run this later:
        final JFrame frame = new JFrame();  
        jfx jf = new jfx(); 
        jf.createJfx();
        frame.getContentPane().add(jf);  
                
        //jf.loadUrl();
        
        frame.setMinimumSize(new Dimension(1024, 768));  
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);  
        frame.setVisible(true); 
    }  

}
