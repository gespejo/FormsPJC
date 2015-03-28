# Enhanced HTML Browser

On the website of Francois Degrelle I came along a webbrowser bean to be used with Oracle Forms. More information you can find at the website of Francois. The bean makes use of a java archive (jdic.jar) and requires some files to be installed under the windows system folder.These files are necessary so you can make use of Internet Explorer or Mozilla Firefox.It didn't get the version of Francois working so I went looking for the used java archive. I found the java archive at the site of sun.  Sun has also a newer version of the java archive (called JDICplus.jar) available.  With the new jar only two dll's have to be available inside the java_path. One disadvantage of this new jar, it only works with version 1.6 of de java runtime.

I have rewritten the Form and the java archive from the example of Francois. The example below show the Oracle Form showing a webpage. I this case mhy own dutch weblog. It is also possible to open pdf document of office documents, they will open with i.e. acrobat or microsoft office. Depending on the programs that have been installed on the client. 

**It can accept both http url and local machine html file names.**

The java code needs, at least, a 1.6 JRE of the Sun Java plug-in, so it won't run with the JInitiator and earlier version of the Sun Java plug-in.

###The Java code

    ehb.java

**The implementation class of the Bean Item**

     oracle.forms.ms.ehb

**The methods you can call**

**Register the bean**

    fbean.register_bean('BL.BEAN', 1, 'oracle.forms.ms.ehb');
This is the very first operation you have to do.

**Get the Forms Window**
     
    fbean.invoke( 'BL.BEAN', 1, 'infoBean', '');

This must be used to retrieve the Forms window that handles the webBrowser, then synchronize its position when the windows is moved. This must be the first property set (in the When-New-Form-Instance trigger).
**Set the URL/File**

    fbean.invoke( 'BL.BEAN', 1, 'setUrl', 'URL');
e.g:

    fbean.invoke( 'BL.BEAN', 1, 'setUrl', 'http://mark-oracle.blogspot.com');        

**Set the border of the bean**

    fbean.invoke( 'BL.BEAN', 1, 'setBorder', 'false');

When you want to use this bean to display a Flash image (*.swf), you would probably prefer not to have any border bounding the image.
In this case, set the border to false.

**Basic navigation**

    fbean.invoke( 'BL.BEAN', 1, 'setNavigation', 'back | forward | refresh' ) ;
e.g.:

    fbean.invoke( 'BL.BEAN', 1, 'setNavigation', 'back');

**GetURL**

    retval := fbean.invoke_char  ( 'BL.BEAN', 1, 'getUrl', '');

**ExecJS**

    retval := fbean.invoke_char  ( 'BL.BEAN', 1, 'execJS', 'javascript');
e.g:

    retval:=fbean.invoke_char(  'BL.BEAN' , 1, 'execJS', 'document.getElementById("myElement").innerHTML;');

**The sample dialog**
- Download the ehb.zip file
- Unzip the ehb.zip file
- Copy the ehb.jar file in your /forms/java/ folder
- Download the JDICplus project zip file 
- Unzip the JDICplus-0.2.2-bin-win32.zip file
- Copy the /lib/JDICplus.jar in your /forms/java/ folder
- Copy the /lib/bin/jdicArc.dll and /lib/bin/jdicWeb.dll in your /windows/system32 folder
- Update your /forms/server/formsweb.cfg configuration file:
   
    archive=frmall.jar,ehb.jar,JDICplus.jar

- Notice that we update the archive tag and not the archive_jini tag because this bean needs the Sun Java plug-in 1.6 and won't run with any older version, including the Oracle JInitiator
- Open the EHTMLBROWSER.fmb module (Oracle Forms 10.1.2)
- Compile all and run the module
- The .jar files must be signed. The ehb.jar file provided with the .zip file are already signed