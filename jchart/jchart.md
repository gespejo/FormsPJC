#JFreeChart integration inside Oracle Forms

This example is based on the jfreechart project which can be found at http://jfree.org/ I’ve taken the example included (PDFViewer.java) with the project and rewritten the PDFViewer class so it can be used as a java bean inside Oracle Forms.

**The implementation class of the Bean Item**

    com.sun.pdfview.PDFViewer

The methods you can call. Register the bean

    fbean.register_bean(hBean, 1, 'oracle.forms.ms.jfcPie');

This is the very first operation you have to do. Set the title of the chart

    fbean.invoke( hBean, 1, 'setTitle','Title');
e.g.

    fbean.invoke( hBean, 1, 'setTitle','Pie Demo Overview');
Set the values:

    hArgs := FBEAN.CREATE_ARGLIST;
    FBEAN.CLEAR_ARGLIST(hArgs) ;
    FBEAN.add_arg(hArgs, to_char(:S_INVENTORY.WAREHOUSE_ID));
    FBEAN.add_arg(hArgs, to_char(:S_INVENTORY.AMOUNT_IN_STOCK));
    FBean.invoke( hBean, 1, 'setValue', hArgs);

Create the chart

    fbean.invoke( hBean, 1, 'createDemoPanel','');

**The sample dialog**
- Download the jchart.zip file
- Unzip the jchart.zip file
- Copy the jchart.jar file in your /forms/java/ folder
- Update your /forms/server/formsweb.cfg configuration file:

    archive=frmall.jar,jfc.jar

- Notice that we update the archive tag and not the archive_jini tag because this bean needs the Sun Java plug-in 1.6 and won't run with any older version, including the Oracle JInitiator
- Download the jfreechart1.0.12.zip from the jfree.org page and extract the jcommon-1.0.15.jar and the jfreechart-1.0.12.jar and copy them inside your /forms/java/ folder. Update the formsweb.cfg and add both jars to the archive entry.

    archive=frmall.jar,jfc.jar,jcommon-1.0.15.jar,jfreechart-1.0.12.jar
- Open the jfreechart.fmb module (Oracle Forms 10.1.2)
- Compile all and run the module
