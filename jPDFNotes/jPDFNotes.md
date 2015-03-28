#jPDFNotes in Oracle Forms

I've included jPDFnotes of qoppa software inside Oracle Forms.

I've build the Form with two Forms buttons: Fill and Save. The Fill button reads a pdf (blob) from the database, encodes it with base64 and then sent it to jPDFNote. After editing the PDF document, adding text like EXPIRE and a red circle it is possible to save the record back to the database by pressing the Save button.

This example is based on the jPDFNotes SimpleFrame example which can be found at http://www.qoppa.com/pdfnotes/guide/sourcesamples.html.

###The implementation class of the Bean Item
    oracle.forms.ms.jPDFNoteSimple
The methods you can call. Register the bean. This is the very first operation you have to do.

    fbean.register_bean('BL.BEAN', 1, ‘oracle.forms.ms.jPDFNoteSimple');

Add text to the bean in base64 encoding:

    fbean.invoke( 'BL.BEAN', 1, 'addText',hArgs);

Show the pdf document which was sent to the bean through the addText component, it also decodes the base64 encoding.

    fbean.invoke( 'BL.BEAN', 1, 'showPDF');

Initialize the save of the edited PDF document.

    fbean.get_property( 'BL.BEAN', 1, 'InitSave');

Get the text of the bean back to forms. It is base64 encoded so it can be get in parts of 32k, which is the limit of Oracle Forms PL/SQL varchar2.

    fbean.get_property( 'BL.BEAN', 1, 'Chunk');

###The sample dialog
-Download the jpdfnote.zip file
-Unzip the jpdfnote.zip file
-Download a copy of the jPDFNotes jar with the jai_codec.jar and jai_imageio.jar at http://www.qoppa.com/pdfnotes/demo/jpnlicense.html
- Copy the jpdfnote.jar and the jPDFNotes.jar,jai_codec.jar and jai_imageio.jar files in your /forms/java/ folder
- Update your /forms/server/formsweb.cfg configuration file:

    archive=frmall.jar,jPDFNotes.jar,jai_codec.jar,jai_imageio.jar,jpdfnote.jar

- Notice that we update the archive tag and not the archive_jini tag because this bean was tested with the Sun Java plug-in 1.6.
- Open the jpdfnotes.fmb module (Oracle Forms 10.1.2)
- Compile all and run the module
- The .jar files must be signed. The jpdfnote.jar file provided with the .zip file is not signed
