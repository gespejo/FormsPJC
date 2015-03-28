create or replace package pdfblob as
/*******************************************************************************
* Name    : PDFBLOB                                                            *
* Version : 0.1                                                                *
* Date    : 28/08/2009                                                         *
* Auteur  : Mark Striekwold                                                    *
* Licence : GPL                                                                *
*                                                                              *
********************************************************************************
*                                                                              *
* This package is based on PL_FPDF Version 0.9.1 of Pierre-Gilles Levallois    *
* who based his version on 1.53 of the FPDF PHP of Olivier PLATHEY             *
* (http://www.fpdf.org/)                                                       *
********************************************************************************
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
********************************************************************************/
   
-- Constantes globales
   PDFBLOB_VERSION constant varchar2(10) := '0.1'; 

-- PDFBLOB public methods
   procedure ln(h number default null);
   function  getX return number;
   procedure setX(px number);
   function  getY return number;
   procedure setY(py number);
   procedure setXY(x number,y number);
   procedure setHeaderProc(headerprocname in varchar2);
   procedure setFooterProc(footerprocname in varchar2);
   procedure setMargins(left number,top number ,right number default -1);
   procedure setLeftMargin( pMargin number);
   procedure setTopMargin(pMargin number);
   procedure setRightMargin(pMargin number);
   procedure setAutoPageBreak(pauto boolean,pMargin number default 0);
   procedure setDisplayMode(zoom varchar2,layout varchar2 default 'continuous');
   procedure setCompression(p_compress boolean default false);
   procedure setTitle(ptitle varchar2);
   procedure setSubject(psubject varchar2);
   procedure setAuthor(pauthor varchar2);
   procedure setKeywords(pkeywords varchar2);
   procedure setCreator(pcreator varchar2);
   procedure setAliasNbPages(palias varchar2 default '{nb}');
   procedure header;
   procedure footer;
   function  pageNo return number;
   procedure setDrawColor(r number,g number default -1,b number default -1);
   procedure setFillColor (r number,g number default -1,b number default -1);
   procedure setTextColor (r number,g number default -1,b number default -1);
   procedure setLineWidth(width number);
   procedure line(x1 number,y1 number,x2 number,y2 number);
   procedure rect(px number,py number,pw number,ph number,pstyle varchar2 default '');
   function  addLink return number;
   procedure setLink(plink number,py number default 0,ppage number default -1);
   procedure link(px number,py number,pw number,ph number,plink varchar2);
   procedure text(px number,py number,ptxt varchar2);
   function  acceptPageBreak return boolean;
   procedure addFont (family varchar2, style varchar2 default '',filename varchar2 default '');
   procedure setFont(pfamily varchar2,pstyle varchar2 default '',psize number default 0);
   function  getStringWidth(pstr varchar2) return number;
   procedure setFontSize(psize number);
   function  getCurrentFontSize return number;
   function  getCurrentFontStyle return varchar2;
   function  getCurrentFontFamily return varchar2;
   procedure setDash(pblack number default 0, pwhite number default 0);
   function  getLineSpacing return number;
   procedure setLineSpacing (pls number);
   procedure openPDF;
   procedure closePDF;
   procedure addPage(orientation varchar2 default '');
   procedure pdfblob  (orientation varchar2 default 'P', unit varchar2 default 'mm', format varchar2 default 'A4');
   procedure error(pmsg varchar2);
   procedure debugEnabled;
   procedure debugDisabled;
   function  getScaleFactor return number;
   function  getImageFromUrl(p_Url varchar2) return ordsys.ordImage;
   procedure cell( pw number
                 , ph number default 0
                 , ptxt varchar2 default ''
                 , pborder varchar2 default '0'
                 , pln number default 0
                 , palign varchar2 default ''
                 , pfill number default 0
                 , plink varchar2 default ''
                 );
   procedure multiCell( pw number
                      , ph number default 0
                      , ptxt varchar2
                      , pborder varchar2 default '0'
                      , palign varchar2 default 'J'
                      , pfill number default 0
                      , phMax number default 0
                      );
   procedure write(pH varchar2,ptxt varchar2,plink varchar2 default null);
   procedure image ( pFile varchar2
                   , pX number
                   , pY number
                   , pWidth number default 0
                   , pHeight number default 0
                   , pType varchar2 default null
                   , pLink varchar2 default null
                   );
   procedure output(pblob in out blob, pname varchar2 default null,pdest varchar2 default null);

end pdfblob; 
/

