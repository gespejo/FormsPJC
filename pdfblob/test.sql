drop table tbtab;

-- just a simple table with any constraints, just for test purpose
-- tbtab == temporary blob table
create table tbtab
(
  id      number,
  waarde  blob
);


declare
   lnumber number :=1;
   
   procedure openpdf
   is
   -- make use of a few  procedures to create a new pdf 
   begin
      pdfblob.pdfblob('P','cm','A4');
      pdfblob.openpdf();
      pdfblob.AddPage();
   end;

   procedure cell ( p_text in varchar2
                , p_text2 in varchar2)
   is
   begin
      -- set the font
      pdfblob.SetFont('arial','',10);
      pdfblob.Cell(0,0.5,p_text,0,lnumber,'L');
      -- jump back one line because cell implements a linefeed 
      pdfblob.Cell(0,-0.5 ,p_text2,0,lnumber,'M');
      lnumber := lnumber+1;
      -- jump back to the line
      pdfblob.Cell(0,0.5,' ',0,lnumber,'L');
      lnumber := lnumber+1;
   end;                
   
   procedure cellheader(p_text in varchar2)
   is
   begin
      -- set the font
      pdfblob.SetFont('arial','B',12);
      -- show the header
      pdfblob.Cell(0,0.5,p_text,0,lnumber,'L');                          
      lnumber := lnumber+1;
      pdfblob.Cell(0,0.5,'---------------------------------------------------',0,lnumber,'L');  
      lnumber := lnumber+1;
   end;          

   procedure linefeed
   is
   begin
      -- set the font
      pdfblob.SetFont('arial','',10);    
      -- make an empty line
      pdfblob.Cell(0,0.5,' ',0,lnumber,'L');
      lnumber := lnumber+1;
   end;      

   procedure closepdf
   is
      blobvar blob;
   begin
      dbms_lob.createtemporary(blobvar,true);
      pdfblob.Output( blobvar );
      
      -- insert the blob inside the  table, in this testcase id is hardcoded 
      insert into tbtab(id,waarde) values (4, blobvar);
      
      dbms_lob.freetemporary(blobvar);
   end;
   
begin
   openpdf();
   cellheader('Client:');
   cell('Client','Mister ABC');
   cell('Clientnumber','376590');
   cell('Address','Street');
   cell('Zipcode','NL-1234AB');
   cell('Location','Silvolde');
   cell('Kantoor e-mail','abc@xyz.com');
   cell('Phonenumber','+31 6 12345678 ');
   linefeed();
   cellheader('Delivery Address:');
   cell('Address','Postalbox 1234');
   cell('Zipcode','NL-1234AB');
   cell('Location','Silvolde');
   cell('Office Location','Yes');
   cell('Reference','2255');
   linefeed();
   cellheader('Details:');
   cell('Product','12346578');
   cell('ID','H. I7549849');
   cell('Description','ZOTSLOT');
   cell('TAX?','N');
   linefeed();
   cellheader('Specification:');
   cell('Total:','2500.00');
   cell('First payment:','');
   cell('  Description (code)','Delivery (79)');
   cell('  Amount','2000.00');
   cell('Second payment','');
   cell('  Discription (code)','Delivery (79-2)');
   cell('  Amount','500.00');
   linefeed();
   closepdf();
end;