package oracle.forms.ms;

import java.awt.BorderLayout;

import java.awt.event.ItemEvent;

import java.io.ByteArrayInputStream;
import java.io.IOException;

import java.net.MalformedURLException;
import java.net.URL;

import javax.swing.JFrame;
import javax.swing.JPanel;

import oracle.forms.ui.VBean;

import org.icepdf.ri.common.SwingController;
import org.icepdf.ri.common.SwingViewBuilder;

import org.icepdf.ri.common.views.DocumentViewController;

import sun.misc.BASE64Decoder;


public class icePDFViewer extends VBean {

    private SwingController controller = null;
    private SwingViewBuilder factory = null;
    private JPanel viewerComponentPanel = null;   
    private static String fileName = null;
   
    private   StringBuffer sb = new StringBuffer();
   
    public void addText(String value)
    {
      System.out.println("addText");
      sb.append(value) ;
    }
   
    //
    // display the whole text
    //
    public void showPDF()
    {
      System.out.println("showPDF");
      BASE64Decoder b64dc = new BASE64Decoder();
      byte[] b;
        try {
            b = b64dc.decodeBuffer( new ByteArrayInputStream(sb.toString().getBytes("UTF-8")));
            controller.openDocument(new ByteArrayInputStream(b), "showPDF", "Demo");     
        } catch (IOException e) {
            // TODO
        }
    }
   
    //
    // clear the TextArea
    //
    public void clearText() {
      sb = new StringBuffer();
    }

    public static void main (String [] args)
    {
       // Get a file from the command line to open
       String filename = args[0];

       icePDFViewer iceview = new icePDFViewer();

       JFrame applicationFrame = new JFrame();
       applicationFrame.getContentPane().add( iceview );

       //iceview.controller.openDocument( filename );
       // iceview.loadDocument("http://www.oracle.com/technology/products/oid/pdf/internet_directory_ds_10gr3.pdf");
        iceview.loadDocument("http://linux-training.be/files/books/LinuxFun.pdf");
        /*
        FileInputStream fin;
        try {
        fin = new FileInputStream("c://temp//oid.txt");
        int ch;
        while ((ch = fin.read()) != -1) {
          iceview.sb.append((char) ch);
        }
        fin.close();
        } catch (FileNotFoundException f) {
        // TODO
        } catch (IOException f) {
        // TODO
        }
        iceview.showPDF();
        */
        applicationFrame.setVisible(true);    
    }

    /**
     * This method initializes
     *
     */
     public icePDFViewer() {
        controller = new SwingController();
        // Buttons from the toolbar can be removed and added here:
        factory = new SwingViewBuilder( controller );
        viewerComponentPanel = factory.buildViewerPanel();
       
        //controller.setToolBarVisible(false);
        factory.buildDemoToolBar();
        setLayout(new BorderLayout());
       
        add(viewerComponentPanel, BorderLayout.CENTER);
    }

    /**
     * Open a local file, given a string filename
     * @param name the name of the file to open
     */
     public void loadDocument (String loadDoc)
     {
         if (loadDoc.startsWith("http:"))
         {
             try {
                controller.openDocument(new URL (loadDoc));
             } catch (MalformedURLException e) {
                 // TODO
                 e.printStackTrace();
                 System.exit(1);
             }
         }
         else
         {
             controller.openDocument(loadDoc);
         }
         controller.setPageFitMode(DocumentViewController.PAGE_FIT_WINDOW_WIDTH, true); 
     }

    public void closeDocument (){
       controller.closeDocument();
    }
    
    public void setZoomFactor(Integer i){
     if (i == 1){
         controller.setPageFitMode(DocumentViewController.PAGE_FIT_WINDOW_HEIGHT, true); 
     } else if (i == 2){
         controller.setPageFitMode(DocumentViewController.PAGE_FIT_WINDOW_WIDTH, true); 
     } else {
         controller.setPageFitMode(DocumentViewController.PAGE_FIT_ACTUAL_SIZE, true);    
     }  
    }
    
}
