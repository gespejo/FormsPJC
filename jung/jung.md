#JUNG inside Oracle Forms

This example is based on the JUNG project which can be found at http://jung.sourceforge.net/index.html.

###The implementation class of the Bean Item

    oracle.forms.ms.jung.orgTree

**The methods you can call**

Register the bean

    fbean.register_bean('BL.BEAN', 1, 'oracle.forms.ms.jung.orgTree');

This is the very first operation you have to do. Set the number of nodes

    fbean.invoke( hBean, 1, ‘init’, number );
e.g. :

    fbean.invoke( hBean, 1, ‘init’, 10 );

Add the nodes: Create a arglist:

    hArgs := fbean.create_arglist;

Fill the arglist

    fbean.add_arg(hArgs, node );
    fbean.add_arg(hArgs, description);
    fbean.add_arg(hArgs, nvl(parent,-1));
e.g.:

    fbean.add_arg(hArgs, employee_id);
    fbean.add_arg(hArgs, names);
    fbean.add_arg(hArgs, nvl(manager_id,-1));

Add the node:

    fbean.invoke( hBean, 1, 'addNode', hArgs);

Show the nodes inside the graph

    fbean.invoke( hBean, 1, ‘showNodes’);

The sample dialog
- Download the jung.zip file
- Unzip the jung.zip file.
- Copy the jung.jar file in your /forms/java/ folder.(Inside the jung.jar is already the jung project included. It is based on jung 2.2.0 )
- Update your /forms/server/formsweb.cfg configuration file:

    archive=frmall.jar,jung.jar

- Notice that we update the archive tag and not the archive_jini tag because this bean was tested with the Sun Java plug-in 1.6.
- Open the jung.fmb module (Oracle Forms 10.1.2)
- Compile all and run the module.
- The .jar files must be signed. The jung.jar file provided with the .zip file is not signed.
