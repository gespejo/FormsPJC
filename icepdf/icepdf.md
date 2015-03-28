# ICEpdf Viewer inside Oracle Forms

###The Java code

This example is based on the ICEpdf which can be found at http://www.icepdf.org.

**The implementation class of the Bean Item**

    oracle.forms.ms.icePDFViewer

###The methods you can call

**Register the bean**

    fbean.register_bean('BL.BEAN', 1, 'oracle.forms.ms.icePDFViewer');

This is the very first operation you have to do.

**Set the URL/File**

    fbean.invoke( hBean, 1, ‘loadDocument’, 'URL');
e.g. :

    fbean.invoke( hBean, 1, ‘loadDocument’, 'http://www.oracle.com/technologies/linux/ubl-faq.pdf');

**Add text to the bean**

Add text in base64 encoding to the bean:

    fbean.invoke( 'BL.BEAN', 1, 'addText',hArgs);

**Show the PDF**

Show the pdf document which was sent to the bean through the addText component, it also decodes the base64 encoding. 

    fbean.invoke( 'BL.BEAN', 1, 'showPDF');

**The sample dialog**

- Download the icepdf.zip file
- Unzip the icepdf.zip file
- Download a copy of the source at 
- Copy the icepdf.jar file in your /forms/java/ folder
- Update your /forms/server/formsweb.cfg configuration file.
 
    archive=frmall.jar, icepdf.jar
- Notice that we update the archive tag and not the archive_jini tag because this bean was tested with the Sun Java plug-in 1.6. 
- Open the icepdfviewer.fmb module (Oracle Forms 10.1.2)
- Compile all and run the module
- The .jar files must be signed,The icepdf.jar file provided with the .zip file is not signed.