#JFXBrowser bean

###The Java code

    jfx.java
    jtcp.java

The implementation class of the Bean Item

    oracle.forms.ms.jfx
    oracle.forms.ms.jtcp

###The methods you can call

**Register the bean**

    fbean.register_bean(hBean, 1, 'oracle.forms.ms.jfx');
    fbean.register_bean(hiddenBean, 1, 'oracle.forms.ms.jtcp');

**This is the very first operation you have to do.**

    fbean.invoke( hBean, 1, 'createJfx');
    fbean.invoke( hiddenBean, 1, 'setUrl', 'http://www.google.nl');

This must be used to retrieve the Forms window that handles the webBrowser, then synchronize its position when the windows is moved. This must be the first property set (in the When-New-Form-Instance trigger).

**Set a new URL**

    fbean.invoke( hiddenBean, 1, 'setUrl', 'http://www.nu.nl');
    fbean.invoke( hBean, 1, 'loadUrl');

**The sample dialog**

- Download the jfx.jar file
- Copy the jfx.jar file in your /forms/java/ folder
- Copy the jfxrt.jar in your /forms/java/ folder (jfxrt is the runtime file of JavaFX and can be found inside java runtime 7 or with javaFX installer).
- Update your /forms/server/formsweb.cfg configuration file:

    archive=frmall.jar,jfx.jar,jfxrt.jar

- Notice that we update the archive tag and not the archive_jini tag because this bean needs the Sun Java plug-in 1.6 and won't run with any older version, including the Oracle JInitiator
- Open the jfx.fmb module (Oracle Forms 10.1.2)
- Compile all and run the module
- The .jar files must be signed The jfx.jar file provided is not signed