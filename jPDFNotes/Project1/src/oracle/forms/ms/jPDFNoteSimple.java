package oracle.forms.ms;

import com.qoppa.pdf.PDFException;
import com.qoppa.pdfNotes.PDFNotesBean;

import java.awt.BorderLayout;
import java.awt.DisplayMode;
import java.awt.GraphicsEnvironment;
import java.awt.event.ComponentAdapter;
import java.awt.event.ComponentEvent;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;

import java.io.InputStream;

import java.io.InputStreamReader;

import java.net.MalformedURLException;
import java.net.URL;

import java.nio.ByteBuffer;

import javax.swing.JCheckBoxMenuItem;
import javax.swing.JFrame;

import javax.swing.JMenu;

import javax.swing.JSeparator;

import oracle.forms.ui.*;

import sun.misc.BASE64Decoder;
import sun.misc.BASE64Encoder;


public class jPDFNoteSimple extends VBean {

    private PDFNotesBean PDFVBean = null;
    private static jPDFNoteSimple sf = null;
    private static String fileName = null;
    private static StringBuffer sb = new StringBuffer(); 
    private static String storeSave = null;
    private static int position = 0;
    
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
            b = b64dc.decodeBuffer(sb.toString());
            //b = b64dc.decodeBuffer( new ByteArrayInputStream(sb.toString().getBytes("UTF-8")));
            PDFVBean.loadPDF( new ByteArrayInputStream(b));      
        } catch (IOException e) {
            // TODO
        } catch (PDFException e) {
            // TODO
        }
    }
    
    public String getInitSave() {
        System.out.println("getLength");
        BASE64Encoder b64en = new BASE64Encoder();
        ByteArrayOutputStream baos = new ByteArrayOutputStream (); 
        try {
                System.out.println("baos");
                PDFVBean.saveDocument(baos);
                System.out.println(baos.size());
                
                storeSave = b64en.encodeBuffer(baos.toByteArray());
                position = 0;
                System.out.println("test.length"+ storeSave.length());
            } catch (IOException e) {
                // TODO
            } catch (PDFException e) {
                // TODO
            }
        
        return ""+storeSave.length();
    }
    
    public String getChunk(){
        System.out.println("getChunk");
        String retstr;
        if (storeSave.length() > position + 32000)
           retstr = storeSave.substring(position, position + 32000);
        else
           retstr = storeSave.substring(position);   
        position = position + 32000;
        return (retstr);
    }
    
    public static void main (String [] args)
    {
        JFrame jf = new JFrame("Oracle Forms Demo");

        jf.setDefaultCloseOperation(javax.swing.JFrame.EXIT_ON_CLOSE);

        DisplayMode dm = GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getDisplayMode();
        jf.setSize((int)Math.min (1024, dm.getWidth() * 0.90), (int)Math.min (768, dm.getHeight() * 0.90));
        jf.setLocationRelativeTo(null);
        
        sf = new jPDFNoteSimple();
        jf.add(sf);
        jf.setVisible(true);
        
        for (int i = 0; i < args.length; i++) {
             if (args[i].equalsIgnoreCase("-help") ||
                    args[i].equalsIgnoreCase("-h") ||
                    args[i].equalsIgnoreCase("-?")) {
                System.out.println("java com.sun.awc.PDFViewer [flags] [file]");
                System.out.println("flags: [-noThumb] [-help or -h or -?]");
                System.exit(0);
            } else {
                fileName = args[i];
            }
        }
        System.out.println(fileName);
 
        jf.addComponentListener(new ComponentAdapter ()
                {
                        public void componentResized (ComponentEvent e)
                        {
                            sf.setLocation (10, 10);
                        }
                        
                        public void componentShown (ComponentEvent e)
                        {
                            sf.setLocation (10, 10);
                            // Load an initial document
                            /*
                            if (fileName == null)
                            {
                               System.out.println("Help!");
                            }
                            else
                            {
                                sf.loadDocument(fileName);
                            }
                            */
                             FileInputStream fin;
                             try {
                             fin = new FileInputStream("c://temp//oid.txt");
                             int ch;
                             while ((ch = fin.read()) != -1) {
                             sf.sb.append((char) ch);
                             }
                             fin.close();   
                             } catch (FileNotFoundException f) {
                             // TODO
                             } catch (IOException f) {
                             // TODO
                             }
                             sf.showPDF();
                        }
                });
    } 
    
    /**
     * This method initializes 
     * 
     */
    public jPDFNoteSimple() 
    {
        PDFVBean = new PDFNotesBean();
        // Buttons from the toolbar can be removed and added here:
        PDFVBean.getEditToolbar().getjbSave().setVisible(false);
        PDFVBean.getToolbar().getjbOpen().setVisible(false);
        PDFVBean.setBorder(javax.swing.BorderFactory.createLineBorder(java.awt.Color.gray,1));
        PDFVBean.revalidate();
        setLayout(new BorderLayout());
        add(PDFVBean, BorderLayout.CENTER);
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
                 PDFVBean.loadPDF(new URL (loadDoc));
             } catch (PDFException e) {
                 // TODO
                 e.printStackTrace();
                 System.exit(1);
             } catch (MalformedURLException e) {
                 // TODO
                 e.printStackTrace();
                 System.exit(1);
             }
         }
         else
         {
             try {
                 PDFVBean.loadPDF(loadDoc);
             } catch (PDFException e) {
                 // TODO
                  e.printStackTrace();
                  System.exit(1);
             }
         }
     }
}  

