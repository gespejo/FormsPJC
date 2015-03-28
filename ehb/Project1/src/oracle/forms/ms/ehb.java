package oracle.forms.ms;

import java.awt.BorderLayout;
import java.awt.Container;
import java.awt.Frame;
import java.awt.Rectangle;
import java.awt.event.ActionEvent;

import java.io.File;

import java.lang.reflect.Method;

import javax.swing.JFrame;
import javax.swing.JPanel;

import oracle.ewt.event.AnyEventListener;

import oracle.forms.engine.Main;
import oracle.forms.handler.IHandler;
import oracle.forms.ui.VBean;

import org.jdic.web.BrComponent;


/**
 * A Bean to display a full Web Browser based on an idea of Francios Degrelle.
 *
 * @author Mark Striekwold
 * @version 1.2
 */
   
public class ehb extends VBean{
    //
    // Variables declaration
    private   oracle.forms.ui.ExtendedFrame ef ;
    private   oracle.ewt.swing.JBufferedFrame winMDI;
    private   Main formsMain = null;
    private   Frame formsTopFrame = null;
    private   int  x,y,w,h;
    private   org.jdic.web.BrComponent brView;
    private   JPanel panel;

    @SuppressWarnings("unchecked")
    
    /** Creates new Embedded HTML Browser */
    public ehb() {
         super();
         BrComponent.DESIGN_MODE = false;
         //BrComponent.setDefaultPaintAlgorithm(BrComponent.PAINT_NATIVE);
         BrComponent.setDefaultPaintAlgorithm(BrComponent.PAINT_JAVA);
         brView = new org.jdic.web.BrComponent();
         Rectangle rec = this.getBounds() ;
         x = (int)rec.getX() ;
         y = (int)rec.getY() ;
         w = (int)rec.getWidth() ;
         h = (int)rec.getHeight() ;
         panel = new JPanel();
         panel.setLayout(new BorderLayout());
         panel.setPreferredSize(this.getPreferredSize());
         panel.add(brView, BorderLayout.CENTER);
         brView.setVisible(false);
         add(panel);
       
         getRect();
    }
    
    public void init(IHandler handler) {
        super.init(handler);   
        // getting the Forms Main class
        try {
            Method method = handler.getClass().getMethod("getApplet", new Class[0]);
            Object applet = method.invoke(handler, new Object[0]);
            if (applet instanceof Main) {
                formsMain = (Main)applet;
            }
        } catch (Exception ex) {
            // print the exception
            System.out.println(ex.toString());
        }
        formsTopFrame = formsMain.getFrame();          
        brView.setBounds(x,y,w,h);
        winMDI = (oracle.ewt.swing.JBufferedFrame)formsMain.getFrame();
    }    
    
    /******************
    *  Set the URL   *
    *****************/
    public boolean setUrl(String pValue) // set the url
    { 
        String url = "";
        brView.setVisible(true);
        brView.setBounds(x,y,w,h);
        try {
            if(! pValue.startsWith("http")) {
                File f = new File(pValue);
                url = new String("file:///"+f.getAbsolutePath());
            }
            else if( pValue.startsWith("http")) {
                //url = new String(java.net.URLEncoder.encode(pValue.toString(), "UTF-8"));
                url = new String(pValue);
            }
            else {
                System.out.println("Item not recognized : "+pValue);
                return false;
            }  
            System.out.println(url);
            brView.setURL(url); 
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
        return true;
    }   

    /******************
    *  Get the URL   *
    *****************/
    public String getUrl(){
        // get the current URL
        String url = brView.getURL();
        // return the URL of the current page
        return url;
    }
    /***********************
    *  Navigation action  *
    **********************/
    public boolean setNavigation(String pValue) // set the navigation action
    {
        System.out.println("Navigation="+pValue);
        
        if(pValue.equalsIgnoreCase("back")) brView.back();
        else if(pValue.equalsIgnoreCase("forward")) brView.forward();
        else if(pValue.equalsIgnoreCase("refresh")) brView.refresh();
        else return false;
        return true;
    }             
    
 /**********************
     * execute javascript *
     **********************/
    public String execJS(String script){
        // execute javascript
        return brView.execJS(script);
    }

    /********************************
     * get HTML of the current page *
     ********************************/
    public String getHTML(){
        // get the HTML of the current page inside the view
        return brView.getHTML();
    }
    /********************************************
    *   get the window that handle the bean    *
    *******************************************/
    public boolean infoBean()
    {
        boolean bCont  = true ;    
        Container cont = this.getParent();
        String s = "" ;
        while (cont!=null) {
            // search for the window
            s = "" + cont.getClass() ;
            if(s.indexOf("oracle.forms.ui.ExtendedFrame")>-1) {
                /*********************
                *   current window  *
                ********************/
                ef = (oracle.forms.ui.ExtendedFrame)cont ;
                System.out.println("------> ExtendedFrame title : "+ef.getTitle());
                // add the listener to the window
                ef.addAnyEventListener(ael);
            }
            cont = cont.getParent() ;
        }
        return true;
    }            

    void getRect()
    {
        Rectangle rec = this.getBounds() ;
        x = (int)rec.getX() ;
        y = (int)rec.getY() ;
        w = (int)rec.getWidth() ;
        h = (int)rec.getHeight() ;        
        //System.out.println("-->"+rec);
    }

    AnyEventListener ael  = new AnyEventListener() {
      public void actionPerformed(ActionEvent actionEvent) {
        String keyText = actionEvent.getActionCommand();
      }
      public void processEventStart(java.util.EventObject eo) {
        String keyText = eo.toString() ;
        //System.out.println(" 2 -->"+keyText);
        if(keyText.indexOf("COMPONENT_MOVED")> -1)
        {
            getRect();
            brView.setBounds(x,y,w,h);
            brView.repaint();
            if(null != winMDI) winMDI.repaint();
        }
      }          
      public void processEventEnd(java.util.EventObject eo) {
        String keyText = eo.toString() ;
      }      
    };

   /**
    * @param args the command line arguments
    */
    public static void main(String args[]) {
        JFrame frame  = new JFrame("EHB");
        ehb e = new ehb(); 
        // Add the control panel and desktop (JDesktopPane) to the application content pane.    
        frame.getContentPane().add(e.brView);
        frame.pack();
        frame.setSize(800, 600); // adjust the frame size using specific dimensions.
        frame.setVisible(true); // show the frame.
        e.setUrl("http://www.google.nl");
                        
        System.out.println(e.getUrl());
        System.out.println(e.getHTML());
    }
}