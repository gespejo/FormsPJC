#JasperReports

Jasper Reports inside Oracle Forms. The java code needs, at least, a 1.6 JRE of the Sun Java plug-in, so it won't run with the JInitiator and earlier version of the Sun Java plug-in.

The Java code

    jRepDB.java

The implementation class of the Bean Item

     oracle.forms.ms.jRepDB

The methods you can call. Register the bean

    fbean.register_bean(hBean, 1, 'oracle.forms.ms.jRepDB');

This is the very first operation you have to do. Setup a connection to the Oracle Database

    fbean.invoke( hBean, 1, 'setConnection', 'localhost|1521|XE|hr|hr');

I make use of the HR schema inside the 11gR2 XE database.Set the report

    fbean.invoke( hBean, 1, 'setReport', 'http://winxp:8889/forms/java/coffee.jasper');

Set the URL of the report you want to display.Note the extension of the file, it is the compiled version of the jasper reports. It will not work with the jrxml file. I used iReport from jasper reports to compile the report.

Set the parameters

    fbean.invoke( hBean, 1, 'setParameters', 'P_LAST_NAME|King');

Set the parameters for the report. For instance if you want only to display King inside the report. 

    P_LASTNAME|King

Display the report

    fbean.invoke( hBean, 1, 'showReport');

This will display the report.Drop the report

    fbean.invoke( hBean, 1, 'dropReport');

This will drop the current report, so you can display a new one.


**The sample dialog**
- Download the coffee.zip
- Unzip the coffee.zip  and copy the file in your /forms/java folder
- Alter the path inside the coffee.jrxml, it now uses my localhost to find the images inside the report
i.e. http://winxp:8889/forms/java/coffee.jpg 
- Compile the report using iReport.
- Copy the jreport.jar file in your /forms/java/ folder
- Copy the jars in your /forms/java/ folder
- Update your /forms/server/formsweb.cfg configuration file:

    archive=frmall.jar,classes12.jar,commons-beanutils-1.8.0.jar,commons-collections-2.1.1.jar,commons-digester-2.1.jar,commons-logging-1.1.1.jar,iText-2.1.7.jar,jasperreports-4.5.1.jar,jreport.jar,log4j-1.2.15.jar,poi-3.7-20101029.jar

- Open the jreport.fmb module (Oracle Forms 10.1.2)
- Compile all and run the module.
- The jreport.jar, classes12.jar and jasperreports-4.5.1jar files must be signed
- The files inside jasper_files.zip are from jasper reports. Be aware of the license which comes with these files.