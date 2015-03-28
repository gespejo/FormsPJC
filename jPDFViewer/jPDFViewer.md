#jPDFViewer
###The Java code

This example is based on the jPDFViewer which can be found at http://www.qoppa.com/jpvindex.html. The implementation class of the Bean Item

    oracle.forms.ms.jPDFsimple

###The methods you can call

**Register the bean**

    fbean.register_bean('BL.BEAN', 1, 'oracle.forms.ms.jPDFsimple');

This is the very first operation you have to do.

**First method:**

Set the URL/File

    fbean.invoke( hBean, 1, ‘loadDocument’, 'URL');
e.g. :
    
    fbean.invoke( hBean, 1, ‘loadDocument’, 'http://www.oracle.com/technology/products/oid/pdf/internet_directory_ds_10gr3.pdf');

**Second method**:

Add text to the bean

Add text in base64 encoding to the bean:

    fbean.invoke( 'BL.BEAN', 1, 'addText',hArgs);

**Show the PDF**

Show the pdf document which was sent to the bean through the addText component, it also decodes the base64 encoding. 

    fbean.invoke( 'BL.BEAN', 1, 'showPDF');

**The sample dialog**

- Download the jpdf.zip file
- Unzip the jpdf.zip file
- Download a copy of the jPDFViewer jar at http://www.qoppa.com/demo/jpvlicense.html
- Copy the jpdf.jar and the jPDFViewer.jar file in your /forms/java/ folder
- Update your /forms/server/formsweb.cfg configuration file:
  
    archive=frmall.jar, jPDFViewer.jar,jpdf.jar

- Notice that we update the archive tag and not the archive_jini tag because this bean was tested with the Sun Java plug-in 1.6. 
- Open the jpdfviewer.fmb module (Oracle Forms 10.1.2)
- Compile all and run the module
- The .jar files must be signed. The jpdf.jar file provided with the .zip file is not signed.
