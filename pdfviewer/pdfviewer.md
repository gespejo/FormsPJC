#PDFViewer

This example is based on the pdf-renderer project which can be found at https://pdf-renderer.dev.java.net/ I�ve taken the example included (PDFViewer.java) with the project and rewritten the PDFViewer class so it can be used as a java bean inside Oracle Forms.

###The implementation class of the Bean Item
    com.sun.pdfview.PDFViewer

**The methods you can call**

Register the bean

    fbean.register_bean('BL.BEAN', 1, 'com.sun.pdfview.PDFViewer');
    
This is the very first operation you have to do. Set the URL/File

    fbean.invoke( hBean, 1, 'doOpenUrl', 'URL');
e.g. :
    
    fbean.invoke( hBean, 1, 'doOpenUrl', 'http://www.oracle.com/technology/products/oid/pdf/internet_directory_ds_10gr3.pdf');

**The sample dialog**
- Download the pdfviewer.zip file
- Unzip the pdfviewer.zip file
- Copy the pdfviewer.jar file in your /forms/java/ folder
- Update your /forms/server/formsweb.cfg configuration file:

    archive=frmall.jar,pdfviewer.jar
    
- Notice that we update the archive tag and not the archive_jini tag because this bean needs the Sun Java plug-in 1.6 and won't run with any older version, including the Oracle JInitiator
- Open the pdfviewer.fmb module (Oracle Forms 10.1.2)
- Compile all and run the module
- The .jar files must be signed. The pdfviewer.jar file provided with the .zip file are already signed.
