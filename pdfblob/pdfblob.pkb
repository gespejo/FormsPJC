create or replace package body pdfblob
as
/*******************************************************************************
* Name : PDFBLOB                                                            *
* Version : 0.1                                                                *
* Date : 28/08/2009                                                         *
* Auteur : Mark Striekwold                                                    *
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

   -- Privates types
   subtype flag    is boolean;
   subtype car     is varchar2 (1);
   subtype word    is varchar2 (80);
   subtype phrase  is varchar2 (255);
   subtype txt     is varchar2 (2000);
   subtype bigtext is varchar2 (32767);
   subtype margin  is number;

   type tbool   is table of boolean          index by binary_integer;
   type tn      is table of number           index by binary_integer;
   type tv4000  is table of varchar2 (4000)  index by binary_integer;
   type tv32k   is table of varchar2 (32767) index by binary_integer;
   type tv4000a is table of varchar2 (4000)  index by word;
   type charset is table of pls_integer      index by car;
   type recfont is record (
      i                             word
    , n                             pls_integer
    , type                          word
    , name                          word
    , dsc                           tv4000
    , up                            word
    , ut                            word
    , cw                            charset
    , enc                           word
    , file                          word
    , diff                          word
    , length1                       word
    , length2                       word
   );
   type fontsarray is table of recfont      index by phrase;
   type recimage   is record (
      n                             number  -- indice d'insertion dans le document
    , i                             number  -- ?
    , w                             number  -- width
    , h                             number  -- height
    , cs                            txt     -- colorspace
    , bpc                           txt     -- Bit per color
    , f                             txt     -- File Format
    , parms                         txt     -- pdf parameter for this image
    , pal                           txt     -- colors palette informations
    , trns                          tn      -- transparency
    , data                          blob    -- Data
   );
   type imagesarray is table of recimage    index by txt;
   type recformat is record (
      largeur                       number
    , hauteur                       number
   );
   type rec2chp is record (
      zero                          txt
    , un                            txt
   );
   type rec5 is record (
      zero                          txt
    , un                            txt
    , deux                          txt
    , trois                         txt
    , quatre                        txt
   );
   type linksarray      is table of rec5;
   type array2dim       is table of rec2chp;
   type arraycharwidths is table of charset     index by word;

-- Private properties
   page                          number;         -- current page number
   n                             number;         -- current object number
   offsets                       tv4000;         -- array of object offsets
   pdfdoc                        tv32k;          -- buffer holding in-memory final PDF document.
   imgblob                       blob;           -- allows creation of persistent blobs for images
   pages                         tv32k;          -- array containing pages
   state                         word;           -- current document state
   b_compress                    flag := false;  -- compression flag
   deforientation                car;            -- default orientation
   curorientation                car;            -- current orientation
   orientationchanges            tbool;          -- array indicating orientation changes
   k                             number;         -- scale factor (number of points in user unit)
   fwpt                          number;
   fhpt                          number;         -- dimensions of page format in points
   fw                            number;
   fh                            number;         -- dimensions of page format in user unit
   wpt                           number;
   hpt                           number;         -- current dimensions of page in points
   w                             number;
   h                             number;         -- current dimensions of page in user unit
   lmargin                       margin;         -- left margin
   tmargin                       margin;         -- top margin
   rmargin                       margin;         -- right margin
   bmargin                       margin;         -- page break margin
   cmargin                       margin;         -- cell margin
   x                             number;
   y                             number;         -- current position in user unit for cell positioning
   lasth                         number;         -- height of last cell printed
   linewidth                     number;         -- line width in user unit
   corefonts                     tv4000a;        -- array of standard font names
   fonts                         fontsarray;     -- array of used fonts
   fontfiles                     fontsarray;     -- array of font files
   diffs                         tv4000;         -- array of encoding differences
   images                        imagesarray;    -- array of used images
   pagelinks                     linksarray;     -- array of links in pages
   links                         array2dim;      -- array of internal links
   fontfamily                    word;           -- current font family
   fontstyle                     word;           -- current font style
   underline                     flag;           -- underlining flag
   currentfont                   recfont;        -- current font info
   fontsizept                    number;         -- current font size in points
   fontsize                      number;         -- current font size in user unit
   drawcolor                     phrase;         -- commands for drawing color
   fillcolor                     phrase;         -- commands for filling color
   textcolor                     phrase;         -- commands for txt color
   colorflag                     flag;           -- indicates whether fill and txt colors are different
   ws                            word;           -- word spacing
   autopagebreak                 flag;           -- automatic page breaking
   pagebreaktrigger              number;         -- threshold used to trigger page breaks
   infooter                      flag;           -- flag set when processing footer
   zoommode                      word;           -- zoom display mode
   layoutmode                    word;           -- layout display mode
   title                         txt;            -- title
   subject                       txt;            -- subject
   author                        txt;            -- author
   keywords                      txt;            -- keywords
   creator                       txt;            -- creator
   aliasnbpages                  word;           -- alias for total number of pages
   pdfversion                    word;           -- PDF version number
   
   
   pdf_charwidths                arraycharwidths; -- Characters table.
   myheader_proc                 txt;             -- Personal Header procedure.
   myfooter_proc                 txt;             -- Personal Footer procedure.
   formatarray                   recformat;       -- Dimension of the format (variable : format).
   gb_mode_debug                 boolean := false;
   linespacing                   number;
   originalsize                  word;
   size1                         word;
   size2                         word;

/*******************************************************************************
*                                                                              *
*           Protected methods : Internal function and procedures               *
*                                                                              *
*******************************************************************************/
   procedure print (  pstr varchar2 )
   is
   begin
      -- Choose the output mode...
      dbms_output.put_line (pstr);
   end print;

----------------------------------------------------------------------------------
-- Testing if method for additionnal fonts exists in this package
-- lv_existing_methods MUST reference all the "p_put..." procedure of the package.
----------------------------------------------------------------------------------
   function methode_exists ( pmethodname varchar2 )
      return boolean
   is
      lv_existing_methods varchar2 (2000)
 :=    'p_putstream,p_putxobjectdict,p_putresourcedict,p_putfonts,p_putimages,p_putresources,'
            || 'p_putinfo,p_putcatalog,p_putheader,p_puttrailer,p_putpages';
   begin
      if (instr (lv_existing_methods, lower (pmethodname)) > 0)
      then
         return true;
      end if;

      return false;
   exception
      when others
      then
         return false;
   end methode_exists;

----------------------------------------------------------------------------------
-- Calculate the length of the final document contained in the plsql table pdfDoc.
----------------------------------------------------------------------------------
   function getpdfdoclength
      return pls_integer
   is
      lg pls_integer := 0;
   begin
      for i in pdfdoc.first .. pdfdoc.last
      loop
         lg := lg + nvl (length (pdfdoc (i)), 0);
      end loop;

      return lg;
   exception
      when others
      then
         error ('getPDFDocLength : ' || sqlerrm);
         return -1;
   end getpdfdoclength;

----------------------------------------------------------------------------------
-- Setting metric for courier Font
----------------------------------------------------------------------------------
   function getfontcourier
      return charset
   is
      myset  charset;
   begin
      --
      -- Courier font.
      --
      for i in 0 .. 255
      loop
         myset (chr (i)) := 600;
      end loop;

      return myset;
   end getfontcourier;

----------------------------------------------------------------------------------
-- Setting metric for helvetica
----------------------------------------------------------------------------------
   function getfonthelvetica
      return charset
   is
      myset charset;
   begin
      -- helvetica font.
      myset (chr (0)) := 278;
      myset (chr (1)) := 278;
      myset (chr (2)) := 278;
      myset (chr (3)) := 278;
      myset (chr (4)) := 278;
      myset (chr (5)) := 278;
      myset (chr (6)) := 278;
      myset (chr (7)) := 278;
      myset (chr (8)) := 278;
      myset (chr (9)) := 278;
      myset (chr (10)) := 278;
      myset (chr (11)) := 278;
      myset (chr (12)) := 278;
      myset (chr (13)) := 278;
      myset (chr (14)) := 278;
      myset (chr (15)) := 278;
      myset (chr (16)) := 278;
      myset (chr (17)) := 278;
      myset (chr (18)) := 278;
      myset (chr (19)) := 278;
      myset (chr (20)) := 278;
      myset (chr (21)) := 278;
      myset (chr (22)) := 278;
      myset (chr (23)) := 278;
      myset (chr (24)) := 278;
      myset (chr (25)) := 278;
      myset (chr (26)) := 278;
      myset (chr (27)) := 278;
      myset (chr (28)) := 278;
      myset (chr (29)) := 278;
      myset (chr (30)) := 278;
      myset (chr (31)) := 278;
      myset (' ') := 278;
      myset ('!') := 278;
      myset ('"') := 355;
      myset ('#') := 556;
      myset ('$') := 556;
      myset ('%') := 889;
      myset ('&') := 667;
      myset ('''') := 191;
      myset ('(') := 333;
      myset (')') := 333;
      myset ('*') := 389;
      myset ('+') := 584;
      myset (',') := 278;
      myset ('-') := 333;
      myset ('.') := 278;
      myset ('/') := 278;
      myset ('0') := 556;
      myset ('1') := 556;
      myset ('2') := 556;
      myset ('3') := 556;
      myset ('4') := 556;
      myset ('5') := 556;
      myset ('6') := 556;
      myset ('7') := 556;
      myset ('8') := 556;
      myset ('9') := 556;
      myset (':') := 278;
      myset (';') := 278;
      myset ('<') := 584;
      myset ('=') := 584;
      myset ('>') := 584;
      myset ('?') := 556;
      myset ('@') := 1015;
      myset ('A') := 667;
      myset ('B') := 667;
      myset ('C') := 722;
      myset ('D') := 722;
      myset ('E') := 667;
      myset ('F') := 611;
      myset ('G') := 778;
      myset ('H') := 722;
      myset ('I') := 278;
      myset ('J') := 500;
      myset ('K') := 667;
      myset ('L') := 556;
      myset ('M') := 833;
      myset ('N') := 722;
      myset ('O') := 778;
      myset ('P') := 667;
      myset ('Q') := 778;
      myset ('R') := 722;
      myset ('S') := 667;
      myset ('T') := 611;
      myset ('U') := 722;
      myset ('V') := 667;
      myset ('W') := 944;
      myset ('X') := 667;
      myset ('Y') := 667;
      myset ('Z') := 611;
      myset ('[') := 278;
      myset ('\') := 278;
      myset (']') := 278;
      myset ('^') := 469;
      myset ('_') := 556;
      myset ('`') := 333;
      myset ('a') := 556;
      myset ('b') := 556;
      myset ('c') := 500;
      myset ('d') := 556;
      myset ('e') := 556;
      myset ('f') := 278;
      myset ('g') := 556;
      myset ('h') := 556;
      myset ('i') := 222;
      myset ('j') := 222;
      myset ('k') := 500;
      myset ('l') := 222;
      myset ('m') := 833;
      myset ('n') := 556;
      myset ('o') := 556;
      myset ('p') := 556;
      myset ('q') := 556;
      myset ('r') := 333;
      myset ('s') := 500;
      myset ('t') := 278;
      myset ('u') := 556;
      myset ('v') := 500;
      myset ('w') := 722;
      myset ('x') := 500;
      myset ('y') := 500;
      myset ('z') := 500;
      myset ('{') := 334;
      myset ('|') := 260;
      myset ('}') := 334;
      myset ('~') := 584;
      myset (chr (127)) := 350;
      myset (chr (128)) := 556;
      myset (chr (129)) := 350;
      myset (chr (130)) := 222;
      myset (chr (131)) := 556;
      myset (chr (132)) := 333;
      myset (chr (133)) := 1000;
      myset (chr (134)) := 556;
      myset (chr (135)) := 556;
      myset (chr (136)) := 333;
      myset (chr (137)) := 1000;
      myset (chr (138)) := 667;
      myset (chr (139)) := 333;
      myset (chr (140)) := 1000;
      myset (chr (141)) := 350;
      myset (chr (142)) := 611;
      myset (chr (143)) := 350;
      myset (chr (144)) := 350;
      myset (chr (145)) := 222;
      myset (chr (146)) := 222;
      myset (chr (147)) := 333;
      myset (chr (148)) := 333;
      myset (chr (149)) := 350;
      myset (chr (150)) := 556;
      myset (chr (151)) := 1000;
      myset (chr (152)) := 333;
      myset (chr (153)) := 1000;
      myset (chr (154)) := 500;
      myset (chr (155)) := 333;
      myset (chr (156)) := 944;
      myset (chr (157)) := 350;
      myset (chr (158)) := 500;
      myset (chr (159)) := 667;
      myset (chr (160)) := 278;
      myset (chr (161)) := 333;
      myset (chr (162)) := 556;
      myset (chr (163)) := 556;
      myset (chr (164)) := 556;
      myset (chr (165)) := 556;
      myset (chr (166)) := 260;
      myset (chr (167)) := 556;
      myset (chr (168)) := 333;
      myset (chr (169)) := 737;
      myset (chr (170)) := 370;
      myset (chr (171)) := 556;
      myset (chr (172)) := 584;
      myset (chr (173)) := 333;
      myset (chr (174)) := 737;
      myset (chr (175)) := 333;
      myset (chr (176)) := 400;
      myset (chr (177)) := 584;
      myset (chr (178)) := 333;
      myset (chr (179)) := 333;
      myset (chr (180)) := 333;
      myset (chr (181)) := 556;
      myset (chr (182)) := 537;
      myset (chr (183)) := 278;
      myset (chr (184)) := 333;
      myset (chr (185)) := 333;
      myset (chr (186)) := 365;
      myset (chr (187)) := 556;
      myset (chr (188)) := 834;
      myset (chr (189)) := 834;
      myset (chr (190)) := 834;
      myset (chr (191)) := 611;
      myset (chr (192)) := 667;
      myset (chr (193)) := 667;
      myset (chr (194)) := 667;
      myset (chr (195)) := 667;
      myset (chr (196)) := 667;
      myset (chr (197)) := 667;
      myset (chr (198)) := 1000;
      myset (chr (199)) := 722;
      myset (chr (200)) := 667;
      myset (chr (201)) := 667;
      myset (chr (202)) := 667;
      myset (chr (203)) := 667;
      myset (chr (204)) := 278;
      myset (chr (205)) := 278;
      myset (chr (206)) := 278;
      myset (chr (207)) := 278;
      myset (chr (208)) := 722;
      myset (chr (209)) := 722;
      myset (chr (210)) := 778;
      myset (chr (211)) := 778;
      myset (chr (212)) := 778;
      myset (chr (213)) := 778;
      myset (chr (214)) := 778;
      myset (chr (215)) := 584;
      myset (chr (216)) := 778;
      myset (chr (217)) := 722;
      myset (chr (218)) := 722;
      myset (chr (219)) := 722;
      myset (chr (220)) := 722;
      myset (chr (221)) := 667;
      myset (chr (222)) := 667;
      myset (chr (223)) := 611;
      myset (chr (224)) := 556;
      myset (chr (225)) := 556;
      myset (chr (226)) := 556;
      myset (chr (227)) := 556;
      myset (chr (228)) := 556;
      myset (chr (229)) := 556;
      myset (chr (230)) := 889;
      myset (chr (231)) := 500;
      myset (chr (232)) := 556;
      myset (chr (233)) := 556;
      myset (chr (234)) := 556;
      myset (chr (235)) := 556;
      myset (chr (236)) := 278;
      myset (chr (237)) := 278;
      myset (chr (238)) := 278;
      myset (chr (239)) := 278;
      myset (chr (240)) := 556;
      myset (chr (241)) := 556;
      myset (chr (242)) := 556;
      myset (chr (243)) := 556;
      myset (chr (244)) := 556;
      myset (chr (245)) := 556;
      myset (chr (246)) := 556;
      myset (chr (247)) := 584;
      myset (chr (248)) := 611;
      myset (chr (249)) := 556;
      myset (chr (250)) := 556;
      myset (chr (251)) := 556;
      myset (chr (252)) := 556;
      myset (chr (253)) := 500;
      myset (chr (254)) := 556;
      myset (chr (255)) := 500;
      return myset;
   end getfonthelvetica;

----------------------------------------------------------------------------------
-- Setting metric for helvetica ITALIC
----------------------------------------------------------------------------------
   function getfonthelveticai
      return charset
   is
      myset       charset;
   begin
      -- helvetica Italic font.
      myset (chr (0)) := 278;
      myset (chr (1)) := 278;
      myset (chr (2)) := 278;
      myset (chr (3)) := 278;
      myset (chr (4)) := 278;
      myset (chr (5)) := 278;
      myset (chr (6)) := 278;
      myset (chr (7)) := 278;
      myset (chr (8)) := 278;
      myset (chr (9)) := 278;
      myset (chr (10)) := 278;
      myset (chr (11)) := 278;
      myset (chr (12)) := 278;
      myset (chr (13)) := 278;
      myset (chr (14)) := 278;
      myset (chr (15)) := 278;
      myset (chr (16)) := 278;
      myset (chr (17)) := 278;
      myset (chr (18)) := 278;
      myset (chr (19)) := 278;
      myset (chr (20)) := 278;
      myset (chr (21)) := 278;
      myset (chr (22)) := 278;
      myset (chr (23)) := 278;
      myset (chr (24)) := 278;
      myset (chr (25)) := 278;
      myset (chr (26)) := 278;
      myset (chr (27)) := 278;
      myset (chr (28)) := 278;
      myset (chr (29)) := 278;
      myset (chr (30)) := 278;
      myset (chr (31)) := 278;
      myset (' ') := 278;
      myset ('!') := 278;
      myset ('"') := 355;
      myset ('#') := 556;
      myset ('$') := 556;
      myset ('%') := 889;
      myset ('&') := 667;
      myset ('''') := 191;
      myset ('(') := 333;
      myset (')') := 333;
      myset ('*') := 389;
      myset ('+') := 584;
      myset (',') := 278;
      myset ('-') := 333;
      myset ('.') := 278;
      myset ('/') := 278;
      myset ('0') := 556;
      myset ('1') := 556;
      myset ('2') := 556;
      myset ('3') := 556;
      myset ('4') := 556;
      myset ('5') := 556;
      myset ('6') := 556;
      myset ('7') := 556;
      myset ('8') := 556;
      myset ('9') := 556;
      myset (':') := 278;
      myset (';') := 278;
      myset ('<') := 584;
      myset ('=') := 584;
      myset ('>') := 584;
      myset ('?') := 556;
      myset ('@') := 1015;
      myset ('A') := 667;
      myset ('B') := 667;
      myset ('C') := 722;
      myset ('D') := 722;
      myset ('E') := 667;
      myset ('F') := 611;
      myset ('G') := 778;
      myset ('H') := 722;
      myset ('I') := 278;
      myset ('J') := 500;
      myset ('K') := 667;
      myset ('L') := 556;
      myset ('M') := 833;
      myset ('N') := 722;
      myset ('O') := 778;
      myset ('P') := 667;
      myset ('Q') := 778;
      myset ('R') := 722;
      myset ('S') := 667;
      myset ('T') := 611;
      myset ('U') := 722;
      myset ('V') := 667;
      myset ('W') := 944;
      myset ('X') := 667;
      myset ('Y') := 667;
      myset ('Z') := 611;
      myset ('[') := 278;
      myset ('\') := 278;
      myset (']') := 278;
      myset ('^') := 469;
      myset ('_') := 556;
      myset ('`') := 333;
      myset ('a') := 556;
      myset ('b') := 556;
      myset ('c') := 500;
      myset ('d') := 556;
      myset ('e') := 556;
      myset ('f') := 278;
      myset ('g') := 556;
      myset ('h') := 556;
      myset ('i') := 222;
      myset ('j') := 222;
      myset ('k') := 500;
      myset ('l') := 222;
      myset ('m') := 833;
      myset ('n') := 556;
      myset ('o') := 556;
      myset ('p') := 556;
      myset ('q') := 556;
      myset ('r') := 333;
      myset ('s') := 500;
      myset ('t') := 278;
      myset ('u') := 556;
      myset ('v') := 500;
      myset ('w') := 722;
      myset ('x') := 500;
      myset ('y') := 500;
      myset ('z') := 500;
      myset ('{') := 334;
      myset ('|') := 260;
      myset ('}') := 334;
      myset ('~') := 584;
      myset (chr (127)) := 350;
      myset (chr (128)) := 556;
      myset (chr (129)) := 350;
      myset (chr (130)) := 222;
      myset (chr (131)) := 556;
      myset (chr (132)) := 333;
      myset (chr (133)) := 1000;
      myset (chr (134)) := 556;
      myset (chr (135)) := 556;
      myset (chr (136)) := 333;
      myset (chr (137)) := 1000;
      myset (chr (138)) := 667;
      myset (chr (139)) := 333;
      myset (chr (140)) := 1000;
      myset (chr (141)) := 350;
      myset (chr (142)) := 611;
      myset (chr (143)) := 350;
      myset (chr (144)) := 350;
      myset (chr (145)) := 222;
      myset (chr (146)) := 222;
      myset (chr (147)) := 333;
      myset (chr (148)) := 333;
      myset (chr (149)) := 350;
      myset (chr (150)) := 556;
      myset (chr (151)) := 1000;
      myset (chr (152)) := 333;
      myset (chr (153)) := 1000;
      myset (chr (154)) := 500;
      myset (chr (155)) := 333;
      myset (chr (156)) := 944;
      myset (chr (157)) := 350;
      myset (chr (158)) := 500;
      myset (chr (159)) := 667;
      myset (chr (160)) := 278;
      myset (chr (161)) := 333;
      myset (chr (162)) := 556;
      myset (chr (163)) := 556;
      myset (chr (164)) := 556;
      myset (chr (165)) := 556;
      myset (chr (166)) := 260;
      myset (chr (167)) := 556;
      myset (chr (168)) := 333;
      myset (chr (169)) := 737;
      myset (chr (170)) := 370;
      myset (chr (171)) := 556;
      myset (chr (172)) := 584;
      myset (chr (173)) := 333;
      myset (chr (174)) := 737;
      myset (chr (175)) := 333;
      myset (chr (176)) := 400;
      myset (chr (177)) := 584;
      myset (chr (178)) := 333;
      myset (chr (179)) := 333;
      myset (chr (180)) := 333;
      myset (chr (181)) := 556;
      myset (chr (182)) := 537;
      myset (chr (183)) := 278;
      myset (chr (184)) := 333;
      myset (chr (185)) := 333;
      myset (chr (186)) := 365;
      myset (chr (187)) := 556;
      myset (chr (188)) := 834;
      myset (chr (189)) := 834;
      myset (chr (190)) := 834;
      myset (chr (191)) := 611;
      myset (chr (192)) := 667;
      myset (chr (193)) := 667;
      myset (chr (194)) := 667;
      myset (chr (195)) := 667;
      myset (chr (196)) := 667;
      myset (chr (197)) := 667;
      myset (chr (198)) := 1000;
      myset (chr (199)) := 722;
      myset (chr (200)) := 667;
      myset (chr (201)) := 667;
      myset (chr (202)) := 667;
      myset (chr (203)) := 667;
      myset (chr (204)) := 278;
      myset (chr (205)) := 278;
      myset (chr (206)) := 278;
      myset (chr (207)) := 278;
      myset (chr (208)) := 722;
      myset (chr (209)) := 722;
      myset (chr (210)) := 778;
      myset (chr (211)) := 778;
      myset (chr (212)) := 778;
      myset (chr (213)) := 778;
      myset (chr (214)) := 778;
      myset (chr (215)) := 584;
      myset (chr (216)) := 778;
      myset (chr (217)) := 722;
      myset (chr (218)) := 722;
      myset (chr (219)) := 722;
      myset (chr (220)) := 722;
      myset (chr (221)) := 667;
      myset (chr (222)) := 667;
      myset (chr (223)) := 611;
      myset (chr (224)) := 556;
      myset (chr (225)) := 556;
      myset (chr (226)) := 556;
      myset (chr (227)) := 556;
      myset (chr (228)) := 556;
      myset (chr (229)) := 556;
      myset (chr (230)) := 889;
      myset (chr (231)) := 500;
      myset (chr (232)) := 556;
      myset (chr (233)) := 556;
      myset (chr (234)) := 556;
      myset (chr (235)) := 556;
      myset (chr (236)) := 278;
      myset (chr (237)) := 278;
      myset (chr (238)) := 278;
      myset (chr (239)) := 278;
      myset (chr (240)) := 556;
      myset (chr (241)) := 556;
      myset (chr (242)) := 556;
      myset (chr (243)) := 556;
      myset (chr (244)) := 556;
      myset (chr (245)) := 556;
      myset (chr (246)) := 556;
      myset (chr (247)) := 584;
      myset (chr (248)) := 611;
      myset (chr (249)) := 556;
      myset (chr (250)) := 556;
      myset (chr (251)) := 556;
      myset (chr (252)) := 556;
      myset (chr (253)) := 500;
      myset (chr (254)) := 556;
      myset (chr (255)) := 500;
      return myset;
   end getfonthelveticai;

----------------------------------------------------------------------------------
-- Setting metric for helvetica BOLD
----------------------------------------------------------------------------------
   function getfonthelveticab
      return charset
   is
      myset       charset;
   begin
      -- helvetica bold font.
      myset (chr (0)) := 278;
      myset (chr (1)) := 278;
      myset (chr (2)) := 278;
      myset (chr (3)) := 278;
      myset (chr (4)) := 278;
      myset (chr (5)) := 278;
      myset (chr (6)) := 278;
      myset (chr (7)) := 278;
      myset (chr (8)) := 278;
      myset (chr (9)) := 278;
      myset (chr (10)) := 278;
      myset (chr (11)) := 278;
      myset (chr (12)) := 278;
      myset (chr (13)) := 278;
      myset (chr (14)) := 278;
      myset (chr (15)) := 278;
      myset (chr (16)) := 278;
      myset (chr (17)) := 278;
      myset (chr (18)) := 278;
      myset (chr (19)) := 278;
      myset (chr (20)) := 278;
      myset (chr (21)) := 278;
      myset (chr (22)) := 278;
      myset (chr (23)) := 278;
      myset (chr (24)) := 278;
      myset (chr (25)) := 278;
      myset (chr (26)) := 278;
      myset (chr (27)) := 278;
      myset (chr (28)) := 278;
      myset (chr (29)) := 278;
      myset (chr (30)) := 278;
      myset (chr (31)) := 278;
      myset (' ') := 278;
      myset ('!') := 333;
      myset ('"') := 474;
      myset ('#') := 556;
      myset ('$') := 556;
      myset ('%') := 889;
      myset ('&') := 722;
      myset ('''') := 238;
      myset ('(') := 333;
      myset (')') := 333;
      myset ('*') := 389;
      myset ('+') := 584;
      myset (',') := 278;
      myset ('-') := 333;
      myset ('.') := 278;
      myset ('/') := 278;
      myset ('0') := 556;
      myset ('1') := 556;
      myset ('2') := 556;
      myset ('3') := 556;
      myset ('4') := 556;
      myset ('5') := 556;
      myset ('6') := 556;
      myset ('7') := 556;
      myset ('8') := 556;
      myset ('9') := 556;
      myset (':') := 333;
      myset (';') := 333;
      myset ('<') := 584;
      myset ('=') := 584;
      myset ('>') := 584;
      myset ('?') := 611;
      myset ('@') := 975;
      myset ('A') := 722;
      myset ('B') := 722;
      myset ('C') := 722;
      myset ('D') := 722;
      myset ('E') := 667;
      myset ('F') := 611;
      myset ('G') := 778;
      myset ('H') := 722;
      myset ('I') := 278;
      myset ('J') := 556;
      myset ('K') := 722;
      myset ('L') := 611;
      myset ('M') := 833;
      myset ('N') := 722;
      myset ('O') := 778;
      myset ('P') := 667;
      myset ('Q') := 778;
      myset ('R') := 722;
      myset ('S') := 667;
      myset ('T') := 611;
      myset ('U') := 722;
      myset ('V') := 667;
      myset ('W') := 944;
      myset ('X') := 667;
      myset ('Y') := 667;
      myset ('Z') := 611;
      myset ('[') := 333;
      myset ('\') := 278;
      myset (']') := 333;
      myset ('^') := 584;
      myset ('_') := 556;
      myset ('`') := 333;
      myset ('a') := 556;
      myset ('b') := 611;
      myset ('c') := 556;
      myset ('d') := 611;
      myset ('e') := 556;
      myset ('f') := 333;
      myset ('g') := 611;
      myset ('h') := 611;
      myset ('i') := 278;
      myset ('j') := 278;
      myset ('k') := 556;
      myset ('l') := 278;
      myset ('m') := 889;
      myset ('n') := 611;
      myset ('o') := 611;
      myset ('p') := 611;
      myset ('q') := 611;
      myset ('r') := 389;
      myset ('s') := 556;
      myset ('t') := 333;
      myset ('u') := 611;
      myset ('v') := 556;
      myset ('w') := 778;
      myset ('x') := 556;
      myset ('y') := 556;
      myset ('z') := 500;
      myset ('{') := 389;
      myset ('|') := 280;
      myset ('}') := 389;
      myset ('~') := 584;
      myset (chr (127)) := 350;
      myset (chr (128)) := 556;
      myset (chr (129)) := 350;
      myset (chr (130)) := 278;
      myset (chr (131)) := 556;
      myset (chr (132)) := 500;
      myset (chr (133)) := 1000;
      myset (chr (134)) := 556;
      myset (chr (135)) := 556;
      myset (chr (136)) := 333;
      myset (chr (137)) := 1000;
      myset (chr (138)) := 667;
      myset (chr (139)) := 333;
      myset (chr (140)) := 1000;
      myset (chr (141)) := 350;
      myset (chr (142)) := 611;
      myset (chr (143)) := 350;
      myset (chr (144)) := 350;
      myset (chr (145)) := 278;
      myset (chr (146)) := 278;
      myset (chr (147)) := 500;
      myset (chr (148)) := 500;
      myset (chr (149)) := 350;
      myset (chr (150)) := 556;
      myset (chr (151)) := 1000;
      myset (chr (152)) := 333;
      myset (chr (153)) := 1000;
      myset (chr (154)) := 556;
      myset (chr (155)) := 333;
      myset (chr (156)) := 944;
      myset (chr (157)) := 350;
      myset (chr (158)) := 500;
      myset (chr (159)) := 667;
      myset (chr (160)) := 278;
      myset (chr (161)) := 333;
      myset (chr (162)) := 556;
      myset (chr (163)) := 556;
      myset (chr (164)) := 556;
      myset (chr (165)) := 556;
      myset (chr (166)) := 280;
      myset (chr (167)) := 556;
      myset (chr (168)) := 333;
      myset (chr (169)) := 737;
      myset (chr (170)) := 370;
      myset (chr (171)) := 556;
      myset (chr (172)) := 584;
      myset (chr (173)) := 333;
      myset (chr (174)) := 737;
      myset (chr (175)) := 333;
      myset (chr (176)) := 400;
      myset (chr (177)) := 584;
      myset (chr (178)) := 333;
      myset (chr (179)) := 333;
      myset (chr (180)) := 333;
      myset (chr (181)) := 611;
      myset (chr (182)) := 556;
      myset (chr (183)) := 278;
      myset (chr (184)) := 333;
      myset (chr (185)) := 333;
      myset (chr (186)) := 365;
      myset (chr (187)) := 556;
      myset (chr (188)) := 834;
      myset (chr (189)) := 834;
      myset (chr (190)) := 834;
      myset (chr (191)) := 611;
      myset (chr (192)) := 722;
      myset (chr (193)) := 722;
      myset (chr (194)) := 722;
      myset (chr (195)) := 722;
      myset (chr (196)) := 722;
      myset (chr (197)) := 722;
      myset (chr (198)) := 1000;
      myset (chr (199)) := 722;
      myset (chr (200)) := 667;
      myset (chr (201)) := 667;
      myset (chr (202)) := 667;
      myset (chr (203)) := 667;
      myset (chr (204)) := 278;
      myset (chr (205)) := 278;
      myset (chr (206)) := 278;
      myset (chr (207)) := 278;
      myset (chr (208)) := 722;
      myset (chr (209)) := 722;
      myset (chr (210)) := 778;
      myset (chr (211)) := 778;
      myset (chr (212)) := 778;
      myset (chr (213)) := 778;
      myset (chr (214)) := 778;
      myset (chr (215)) := 584;
      myset (chr (216)) := 778;
      myset (chr (217)) := 722;
      myset (chr (218)) := 722;
      myset (chr (219)) := 722;
      myset (chr (220)) := 722;
      myset (chr (221)) := 667;
      myset (chr (222)) := 667;
      myset (chr (223)) := 611;
      myset (chr (224)) := 556;
      myset (chr (225)) := 556;
      myset (chr (226)) := 556;
      myset (chr (227)) := 556;
      myset (chr (228)) := 556;
      myset (chr (229)) := 556;
      myset (chr (230)) := 889;
      myset (chr (231)) := 556;
      myset (chr (232)) := 556;
      myset (chr (233)) := 556;
      myset (chr (234)) := 556;
      myset (chr (235)) := 556;
      myset (chr (236)) := 278;
      myset (chr (237)) := 278;
      myset (chr (238)) := 278;
      myset (chr (239)) := 278;
      myset (chr (240)) := 611;
      myset (chr (241)) := 611;
      myset (chr (242)) := 611;
      myset (chr (243)) := 611;
      myset (chr (244)) := 611;
      myset (chr (245)) := 611;
      myset (chr (246)) := 611;
      myset (chr (247)) := 584;
      myset (chr (248)) := 611;
      myset (chr (249)) := 611;
      myset (chr (250)) := 611;
      myset (chr (251)) := 611;
      myset (chr (252)) := 611;
      myset (chr (253)) := 556;
      myset (chr (254)) := 611;
      myset (chr (255)) := 556;
      return myset;
   end getfonthelveticab;

----------------------------------------------------------------------------------
-- Setting metric for helvetica BOLD ITALIC
----------------------------------------------------------------------------------
   function getfonthelveticabi
      return charset
   is
      myset       charset;
   begin
      -- helvetica bold italic font.
      myset (chr (0)) := 278;
      myset (chr (1)) := 278;
      myset (chr (2)) := 278;
      myset (chr (3)) := 278;
      myset (chr (4)) := 278;
      myset (chr (5)) := 278;
      myset (chr (6)) := 278;
      myset (chr (7)) := 278;
      myset (chr (8)) := 278;
      myset (chr (9)) := 278;
      myset (chr (10)) := 278;
      myset (chr (11)) := 278;
      myset (chr (12)) := 278;
      myset (chr (13)) := 278;
      myset (chr (14)) := 278;
      myset (chr (15)) := 278;
      myset (chr (16)) := 278;
      myset (chr (17)) := 278;
      myset (chr (18)) := 278;
      myset (chr (19)) := 278;
      myset (chr (20)) := 278;
      myset (chr (21)) := 278;
      myset (chr (22)) := 278;
      myset (chr (23)) := 278;
      myset (chr (24)) := 278;
      myset (chr (25)) := 278;
      myset (chr (26)) := 278;
      myset (chr (27)) := 278;
      myset (chr (28)) := 278;
      myset (chr (29)) := 278;
      myset (chr (30)) := 278;
      myset (chr (31)) := 278;
      myset (' ') := 278;
      myset ('!') := 333;
      myset ('"') := 474;
      myset ('#') := 556;
      myset ('$') := 556;
      myset ('%') := 889;
      myset ('&') := 722;
      myset ('''') := 238;
      myset ('(') := 333;
      myset (')') := 333;
      myset ('*') := 389;
      myset ('+') := 584;
      myset (',') := 278;
      myset ('-') := 333;
      myset ('.') := 278;
      myset ('/') := 278;
      myset ('0') := 556;
      myset ('1') := 556;
      myset ('2') := 556;
      myset ('3') := 556;
      myset ('4') := 556;
      myset ('5') := 556;
      myset ('6') := 556;
      myset ('7') := 556;
      myset ('8') := 556;
      myset ('9') := 556;
      myset (':') := 333;
      myset (';') := 333;
      myset ('<') := 584;
      myset ('=') := 584;
      myset ('>') := 584;
      myset ('?') := 611;
      myset ('@') := 975;
      myset ('A') := 722;
      myset ('B') := 722;
      myset ('C') := 722;
      myset ('D') := 722;
      myset ('E') := 667;
      myset ('F') := 611;
      myset ('G') := 778;
      myset ('H') := 722;
      myset ('I') := 278;
      myset ('J') := 556;
      myset ('K') := 722;
      myset ('L') := 611;
      myset ('M') := 833;
      myset ('N') := 722;
      myset ('O') := 778;
      myset ('P') := 667;
      myset ('Q') := 778;
      myset ('R') := 722;
      myset ('S') := 667;
      myset ('T') := 611;
      myset ('U') := 722;
      myset ('V') := 667;
      myset ('W') := 944;
      myset ('X') := 667;
      myset ('Y') := 667;
      myset ('Z') := 611;
      myset ('[') := 333;
      myset ('\') := 278;
      myset (']') := 333;
      myset ('^') := 584;
      myset ('_') := 556;
      myset ('`') := 333;
      myset ('a') := 556;
      myset ('b') := 611;
      myset ('c') := 556;
      myset ('d') := 611;
      myset ('e') := 556;
      myset ('f') := 333;
      myset ('g') := 611;
      myset ('h') := 611;
      myset ('i') := 278;
      myset ('j') := 278;
      myset ('k') := 556;
      myset ('l') := 278;
      myset ('m') := 889;
      myset ('n') := 611;
      myset ('o') := 611;
      myset ('p') := 611;
      myset ('q') := 611;
      myset ('r') := 389;
      myset ('s') := 556;
      myset ('t') := 333;
      myset ('u') := 611;
      myset ('v') := 556;
      myset ('w') := 778;
      myset ('x') := 556;
      myset ('y') := 556;
      myset ('z') := 500;
      myset ('{') := 389;
      myset ('|') := 280;
      myset ('}') := 389;
      myset ('~') := 584;
      myset (chr (127)) := 350;
      myset (chr (128)) := 556;
      myset (chr (129)) := 350;
      myset (chr (130)) := 278;
      myset (chr (131)) := 556;
      myset (chr (132)) := 500;
      myset (chr (133)) := 1000;
      myset (chr (134)) := 556;
      myset (chr (135)) := 556;
      myset (chr (136)) := 333;
      myset (chr (137)) := 1000;
      myset (chr (138)) := 667;
      myset (chr (139)) := 333;
      myset (chr (140)) := 1000;
      myset (chr (141)) := 350;
      myset (chr (142)) := 611;
      myset (chr (143)) := 350;
      myset (chr (144)) := 350;
      myset (chr (145)) := 278;
      myset (chr (146)) := 278;
      myset (chr (147)) := 500;
      myset (chr (148)) := 500;
      myset (chr (149)) := 350;
      myset (chr (150)) := 556;
      myset (chr (151)) := 1000;
      myset (chr (152)) := 333;
      myset (chr (153)) := 1000;
      myset (chr (154)) := 556;
      myset (chr (155)) := 333;
      myset (chr (156)) := 944;
      myset (chr (157)) := 350;
      myset (chr (158)) := 500;
      myset (chr (159)) := 667;
      myset (chr (160)) := 278;
      myset (chr (161)) := 333;
      myset (chr (162)) := 556;
      myset (chr (163)) := 556;
      myset (chr (164)) := 556;
      myset (chr (165)) := 556;
      myset (chr (166)) := 280;
      myset (chr (167)) := 556;
      myset (chr (168)) := 333;
      myset (chr (169)) := 737;
      myset (chr (170)) := 370;
      myset (chr (171)) := 556;
      myset (chr (172)) := 584;
      myset (chr (173)) := 333;
      myset (chr (174)) := 737;
      myset (chr (175)) := 333;
      myset (chr (176)) := 400;
      myset (chr (177)) := 584;
      myset (chr (178)) := 333;
      myset (chr (179)) := 333;
      myset (chr (180)) := 333;
      myset (chr (181)) := 611;
      myset (chr (182)) := 556;
      myset (chr (183)) := 278;
      myset (chr (184)) := 333;
      myset (chr (185)) := 333;
      myset (chr (186)) := 365;
      myset (chr (187)) := 556;
      myset (chr (188)) := 834;
      myset (chr (189)) := 834;
      myset (chr (190)) := 834;
      myset (chr (191)) := 611;
      myset (chr (192)) := 722;
      myset (chr (193)) := 722;
      myset (chr (194)) := 722;
      myset (chr (195)) := 722;
      myset (chr (196)) := 722;
      myset (chr (197)) := 722;
      myset (chr (198)) := 1000;
      myset (chr (199)) := 722;
      myset (chr (200)) := 667;
      myset (chr (201)) := 667;
      myset (chr (202)) := 667;
      myset (chr (203)) := 667;
      myset (chr (204)) := 278;
      myset (chr (205)) := 278;
      myset (chr (206)) := 278;
      myset (chr (207)) := 278;
      myset (chr (208)) := 722;
      myset (chr (209)) := 722;
      myset (chr (210)) := 778;
      myset (chr (211)) := 778;
      myset (chr (212)) := 778;
      myset (chr (213)) := 778;
      myset (chr (214)) := 778;
      myset (chr (215)) := 584;
      myset (chr (216)) := 778;
      myset (chr (217)) := 722;
      myset (chr (218)) := 722;
      myset (chr (219)) := 722;
      myset (chr (220)) := 722;
      myset (chr (221)) := 667;
      myset (chr (222)) := 667;
      myset (chr (223)) := 611;
      myset (chr (224)) := 556;
      myset (chr (225)) := 556;
      myset (chr (226)) := 556;
      myset (chr (227)) := 556;
      myset (chr (228)) := 556;
      myset (chr (229)) := 556;
      myset (chr (230)) := 889;
      myset (chr (231)) := 556;
      myset (chr (232)) := 556;
      myset (chr (233)) := 556;
      myset (chr (234)) := 556;
      myset (chr (235)) := 556;
      myset (chr (236)) := 278;
      myset (chr (237)) := 278;
      myset (chr (238)) := 278;
      myset (chr (239)) := 278;
      myset (chr (240)) := 611;
      myset (chr (241)) := 611;
      myset (chr (242)) := 611;
      myset (chr (243)) := 611;
      myset (chr (244)) := 611;
      myset (chr (245)) := 611;
      myset (chr (246)) := 611;
      myset (chr (247)) := 584;
      myset (chr (248)) := 611;
      myset (chr (249)) := 611;
      myset (chr (250)) := 611;
      myset (chr (251)) := 611;
      myset (chr (252)) := 611;
      myset (chr (253)) := 556;
      myset (chr (254)) := 611;
      myset (chr (255)) := 556;
      return myset;
   end getfonthelveticabi;

----------------------------------------------------------------------------------
-- Setting metric for times
----------------------------------------------------------------------------------
   function getfonttimes
      return charset
   is
      myset       charset;
   begin
      -- Times font.
      myset (chr (0)) := 250;
      myset (chr (1)) := 250;
      myset (chr (2)) := 250;
      myset (chr (3)) := 250;
      myset (chr (4)) := 250;
      myset (chr (5)) := 250;
      myset (chr (6)) := 250;
      myset (chr (7)) := 250;
      myset (chr (8)) := 250;
      myset (chr (9)) := 250;
      myset (chr (10)) := 250;
      myset (chr (11)) := 250;
      myset (chr (12)) := 250;
      myset (chr (13)) := 250;
      myset (chr (14)) := 250;
      myset (chr (15)) := 250;
      myset (chr (16)) := 250;
      myset (chr (17)) := 250;
      myset (chr (18)) := 250;
      myset (chr (19)) := 250;
      myset (chr (20)) := 250;
      myset (chr (21)) := 250;
      myset (chr (22)) := 250;
      myset (chr (23)) := 250;
      myset (chr (24)) := 250;
      myset (chr (25)) := 250;
      myset (chr (26)) := 250;
      myset (chr (27)) := 250;
      myset (chr (28)) := 250;
      myset (chr (29)) := 250;
      myset (chr (30)) := 250;
      myset (chr (31)) := 250;
      myset (' ') := 250;
      myset ('!') := 333;
      myset ('"') := 408;
      myset ('#') := 500;
      myset ('$') := 500;
      myset ('%') := 833;
      myset ('&') := 778;
      myset ('''') := 180;
      myset ('(') := 333;
      myset (')') := 333;
      myset ('*') := 500;
      myset ('+') := 564;
      myset (',') := 250;
      myset ('-') := 333;
      myset ('.') := 250;
      myset ('/') := 278;
      myset ('0') := 500;
      myset ('1') := 500;
      myset ('2') := 500;
      myset ('3') := 500;
      myset ('4') := 500;
      myset ('5') := 500;
      myset ('6') := 500;
      myset ('7') := 500;
      myset ('8') := 500;
      myset ('9') := 500;
      myset (':') := 278;
      myset (';') := 278;
      myset ('<') := 564;
      myset ('=') := 564;
      myset ('>') := 564;
      myset ('?') := 444;
      myset ('@') := 921;
      myset ('A') := 722;
      myset ('B') := 667;
      myset ('C') := 667;
      myset ('D') := 722;
      myset ('E') := 611;
      myset ('F') := 556;
      myset ('G') := 722;
      myset ('H') := 722;
      myset ('I') := 333;
      myset ('J') := 389;
      myset ('K') := 722;
      myset ('L') := 611;
      myset ('M') := 889;
      myset ('N') := 722;
      myset ('O') := 722;
      myset ('P') := 556;
      myset ('Q') := 722;
      myset ('R') := 667;
      myset ('S') := 556;
      myset ('T') := 611;
      myset ('U') := 722;
      myset ('V') := 722;
      myset ('W') := 944;
      myset ('X') := 722;
      myset ('Y') := 722;
      myset ('Z') := 611;
      myset ('[') := 333;
      myset ('\') := 278;
      myset (']') := 333;
      myset ('^') := 469;
      myset ('_') := 500;
      myset ('`') := 333;
      myset ('a') := 444;
      myset ('b') := 500;
      myset ('c') := 444;
      myset ('d') := 500;
      myset ('e') := 444;
      myset ('f') := 333;
      myset ('g') := 500;
      myset ('h') := 500;
      myset ('i') := 278;
      myset ('j') := 278;
      myset ('k') := 500;
      myset ('l') := 278;
      myset ('m') := 778;
      myset ('n') := 500;
      myset ('o') := 500;
      myset ('p') := 500;
      myset ('q') := 500;
      myset ('r') := 333;
      myset ('s') := 389;
      myset ('t') := 278;
      myset ('u') := 500;
      myset ('v') := 500;
      myset ('w') := 722;
      myset ('x') := 500;
      myset ('y') := 500;
      myset ('z') := 444;
      myset ('{') := 480;
      myset ('|') := 200;
      myset ('}') := 480;
      myset ('~') := 541;
      myset (chr (127)) := 350;
      myset (chr (128)) := 500;
      myset (chr (129)) := 350;
      myset (chr (130)) := 333;
      myset (chr (131)) := 500;
      myset (chr (132)) := 444;
      myset (chr (133)) := 1000;
      myset (chr (134)) := 500;
      myset (chr (135)) := 500;
      myset (chr (136)) := 333;
      myset (chr (137)) := 1000;
      myset (chr (138)) := 556;
      myset (chr (139)) := 333;
      myset (chr (140)) := 889;
      myset (chr (141)) := 350;
      myset (chr (142)) := 611;
      myset (chr (143)) := 350;
      myset (chr (144)) := 350;
      myset (chr (145)) := 333;
      myset (chr (146)) := 333;
      myset (chr (147)) := 444;
      myset (chr (148)) := 444;
      myset (chr (149)) := 350;
      myset (chr (150)) := 500;
      myset (chr (151)) := 1000;
      myset (chr (152)) := 333;
      myset (chr (153)) := 980;
      myset (chr (154)) := 389;
      myset (chr (155)) := 333;
      myset (chr (156)) := 722;
      myset (chr (157)) := 350;
      myset (chr (158)) := 444;
      myset (chr (159)) := 722;
      myset (chr (160)) := 250;
      myset (chr (161)) := 333;
      myset (chr (162)) := 500;
      myset (chr (163)) := 500;
      myset (chr (164)) := 500;
      myset (chr (165)) := 500;
      myset (chr (166)) := 200;
      myset (chr (167)) := 500;
      myset (chr (168)) := 333;
      myset (chr (169)) := 760;
      myset (chr (170)) := 276;
      myset (chr (171)) := 500;
      myset (chr (172)) := 564;
      myset (chr (173)) := 333;
      myset (chr (174)) := 760;
      myset (chr (175)) := 333;
      myset (chr (176)) := 400;
      myset (chr (177)) := 564;
      myset (chr (178)) := 300;
      myset (chr (179)) := 300;
      myset (chr (180)) := 333;
      myset (chr (181)) := 500;
      myset (chr (182)) := 453;
      myset (chr (183)) := 250;
      myset (chr (184)) := 333;
      myset (chr (185)) := 300;
      myset (chr (186)) := 310;
      myset (chr (187)) := 500;
      myset (chr (188)) := 750;
      myset (chr (189)) := 750;
      myset (chr (190)) := 750;
      myset (chr (191)) := 444;
      myset (chr (192)) := 722;
      myset (chr (193)) := 722;
      myset (chr (194)) := 722;
      myset (chr (195)) := 722;
      myset (chr (196)) := 722;
      myset (chr (197)) := 722;
      myset (chr (198)) := 889;
      myset (chr (199)) := 667;
      myset (chr (200)) := 611;
      myset (chr (201)) := 611;
      myset (chr (202)) := 611;
      myset (chr (203)) := 611;
      myset (chr (204)) := 333;
      myset (chr (205)) := 333;
      myset (chr (206)) := 333;
      myset (chr (207)) := 333;
      myset (chr (208)) := 722;
      myset (chr (209)) := 722;
      myset (chr (210)) := 722;
      myset (chr (211)) := 722;
      myset (chr (212)) := 722;
      myset (chr (213)) := 722;
      myset (chr (214)) := 722;
      myset (chr (215)) := 564;
      myset (chr (216)) := 722;
      myset (chr (217)) := 722;
      myset (chr (218)) := 722;
      myset (chr (219)) := 722;
      myset (chr (220)) := 722;
      myset (chr (221)) := 722;
      myset (chr (222)) := 556;
      myset (chr (223)) := 500;
      myset (chr (224)) := 444;
      myset (chr (225)) := 444;
      myset (chr (226)) := 444;
      myset (chr (227)) := 444;
      myset (chr (228)) := 444;
      myset (chr (229)) := 444;
      myset (chr (230)) := 667;
      myset (chr (231)) := 444;
      myset (chr (232)) := 444;
      myset (chr (233)) := 444;
      myset (chr (234)) := 444;
      myset (chr (235)) := 444;
      myset (chr (236)) := 278;
      myset (chr (237)) := 278;
      myset (chr (238)) := 278;
      myset (chr (239)) := 278;
      myset (chr (240)) := 500;
      myset (chr (241)) := 500;
      myset (chr (242)) := 500;
      myset (chr (243)) := 500;
      myset (chr (244)) := 500;
      myset (chr (245)) := 500;
      myset (chr (246)) := 500;
      myset (chr (247)) := 564;
      myset (chr (248)) := 500;
      myset (chr (249)) := 500;
      myset (chr (250)) := 500;
      myset (chr (251)) := 500;
      myset (chr (252)) := 500;
      myset (chr (253)) := 500;
      myset (chr (254)) := 500;
      myset (chr (255)) := 500;
      return myset;
   end getfonttimes;

----------------------------------------------------------------------------------
-- Setting metric for times ITALIC
----------------------------------------------------------------------------------
   function getfonttimesi
      return charset
   is
      myset       charset;
   begin
      -- Times italic font.
      myset (chr (0)) := 250;
      myset (chr (1)) := 250;
      myset (chr (2)) := 250;
      myset (chr (3)) := 250;
      myset (chr (4)) := 250;
      myset (chr (5)) := 250;
      myset (chr (6)) := 250;
      myset (chr (7)) := 250;
      myset (chr (8)) := 250;
      myset (chr (9)) := 250;
      myset (chr (10)) := 250;
      myset (chr (11)) := 250;
      myset (chr (12)) := 250;
      myset (chr (13)) := 250;
      myset (chr (14)) := 250;
      myset (chr (15)) := 250;
      myset (chr (16)) := 250;
      myset (chr (17)) := 250;
      myset (chr (18)) := 250;
      myset (chr (19)) := 250;
      myset (chr (20)) := 250;
      myset (chr (21)) := 250;
      myset (chr (22)) := 250;
      myset (chr (23)) := 250;
      myset (chr (24)) := 250;
      myset (chr (25)) := 250;
      myset (chr (26)) := 250;
      myset (chr (27)) := 250;
      myset (chr (28)) := 250;
      myset (chr (29)) := 250;
      myset (chr (30)) := 250;
      myset (chr (31)) := 250;
      myset (' ') := 250;
      myset ('!') := 333;
      myset ('"') := 420;
      myset ('#') := 500;
      myset ('$') := 500;
      myset ('%') := 833;
      myset ('&') := 778;
      myset ('''') := 214;
      myset ('(') := 333;
      myset (')') := 333;
      myset ('*') := 500;
      myset ('+') := 675;
      myset (',') := 250;
      myset ('-') := 333;
      myset ('.') := 250;
      myset ('/') := 278;
      myset ('0') := 500;
      myset ('1') := 500;
      myset ('2') := 500;
      myset ('3') := 500;
      myset ('4') := 500;
      myset ('5') := 500;
      myset ('6') := 500;
      myset ('7') := 500;
      myset ('8') := 500;
      myset ('9') := 500;
      myset (':') := 333;
      myset (';') := 333;
      myset ('<') := 675;
      myset ('=') := 675;
      myset ('>') := 675;
      myset ('?') := 500;
      myset ('@') := 920;
      myset ('A') := 611;
      myset ('B') := 611;
      myset ('C') := 667;
      myset ('D') := 722;
      myset ('E') := 611;
      myset ('F') := 611;
      myset ('G') := 722;
      myset ('H') := 722;
      myset ('I') := 333;
      myset ('J') := 444;
      myset ('K') := 667;
      myset ('L') := 556;
      myset ('M') := 833;
      myset ('N') := 667;
      myset ('O') := 722;
      myset ('P') := 611;
      myset ('Q') := 722;
      myset ('R') := 611;
      myset ('S') := 500;
      myset ('T') := 556;
      myset ('U') := 722;
      myset ('V') := 611;
      myset ('W') := 833;
      myset ('X') := 611;
      myset ('Y') := 556;
      myset ('Z') := 556;
      myset ('[') := 389;
      myset ('\') := 278;
      myset (']') := 389;
      myset ('^') := 422;
      myset ('_') := 500;
      myset ('`') := 333;
      myset ('a') := 500;
      myset ('b') := 500;
      myset ('c') := 444;
      myset ('d') := 500;
      myset ('e') := 444;
      myset ('f') := 278;
      myset ('g') := 500;
      myset ('h') := 500;
      myset ('i') := 278;
      myset ('j') := 278;
      myset ('k') := 444;
      myset ('l') := 278;
      myset ('m') := 722;
      myset ('n') := 500;
      myset ('o') := 500;
      myset ('p') := 500;
      myset ('q') := 500;
      myset ('r') := 389;
      myset ('s') := 389;
      myset ('t') := 278;
      myset ('u') := 500;
      myset ('v') := 444;
      myset ('w') := 667;
      myset ('x') := 444;
      myset ('y') := 444;
      myset ('z') := 389;
      myset ('{') := 400;
      myset ('|') := 275;
      myset ('}') := 400;
      myset ('~') := 541;
      myset (chr (127)) := 350;
      myset (chr (128)) := 500;
      myset (chr (129)) := 350;
      myset (chr (130)) := 333;
      myset (chr (131)) := 500;
      myset (chr (132)) := 556;
      myset (chr (133)) := 889;
      myset (chr (134)) := 500;
      myset (chr (135)) := 500;
      myset (chr (136)) := 333;
      myset (chr (137)) := 1000;
      myset (chr (138)) := 500;
      myset (chr (139)) := 333;
      myset (chr (140)) := 944;
      myset (chr (141)) := 350;
      myset (chr (142)) := 556;
      myset (chr (143)) := 350;
      myset (chr (144)) := 350;
      myset (chr (145)) := 333;
      myset (chr (146)) := 333;
      myset (chr (147)) := 556;
      myset (chr (148)) := 556;
      myset (chr (149)) := 350;
      myset (chr (150)) := 500;
      myset (chr (151)) := 889;
      myset (chr (152)) := 333;
      myset (chr (153)) := 980;
      myset (chr (154)) := 389;
      myset (chr (155)) := 333;
      myset (chr (156)) := 667;
      myset (chr (157)) := 350;
      myset (chr (158)) := 389;
      myset (chr (159)) := 556;
      myset (chr (160)) := 250;
      myset (chr (161)) := 389;
      myset (chr (162)) := 500;
      myset (chr (163)) := 500;
      myset (chr (164)) := 500;
      myset (chr (165)) := 500;
      myset (chr (166)) := 275;
      myset (chr (167)) := 500;
      myset (chr (168)) := 333;
      myset (chr (169)) := 760;
      myset (chr (170)) := 276;
      myset (chr (171)) := 500;
      myset (chr (172)) := 675;
      myset (chr (173)) := 333;
      myset (chr (174)) := 760;
      myset (chr (175)) := 333;
      myset (chr (176)) := 400;
      myset (chr (177)) := 675;
      myset (chr (178)) := 300;
      myset (chr (179)) := 300;
      myset (chr (180)) := 333;
      myset (chr (181)) := 500;
      myset (chr (182)) := 523;
      myset (chr (183)) := 250;
      myset (chr (184)) := 333;
      myset (chr (185)) := 300;
      myset (chr (186)) := 310;
      myset (chr (187)) := 500;
      myset (chr (188)) := 750;
      myset (chr (189)) := 750;
      myset (chr (190)) := 750;
      myset (chr (191)) := 500;
      myset (chr (192)) := 611;
      myset (chr (193)) := 611;
      myset (chr (194)) := 611;
      myset (chr (195)) := 611;
      myset (chr (196)) := 611;
      myset (chr (197)) := 611;
      myset (chr (198)) := 889;
      myset (chr (199)) := 667;
      myset (chr (200)) := 611;
      myset (chr (201)) := 611;
      myset (chr (202)) := 611;
      myset (chr (203)) := 611;
      myset (chr (204)) := 333;
      myset (chr (205)) := 333;
      myset (chr (206)) := 333;
      myset (chr (207)) := 333;
      myset (chr (208)) := 722;
      myset (chr (209)) := 667;
      myset (chr (210)) := 722;
      myset (chr (211)) := 722;
      myset (chr (212)) := 722;
      myset (chr (213)) := 722;
      myset (chr (214)) := 722;
      myset (chr (215)) := 675;
      myset (chr (216)) := 722;
      myset (chr (217)) := 722;
      myset (chr (218)) := 722;
      myset (chr (219)) := 722;
      myset (chr (220)) := 722;
      myset (chr (221)) := 556;
      myset (chr (222)) := 611;
      myset (chr (223)) := 500;
      myset (chr (224)) := 500;
      myset (chr (225)) := 500;
      myset (chr (226)) := 500;
      myset (chr (227)) := 500;
      myset (chr (228)) := 500;
      myset (chr (229)) := 500;
      myset (chr (230)) := 667;
      myset (chr (231)) := 444;
      myset (chr (232)) := 444;
      myset (chr (233)) := 444;
      myset (chr (234)) := 444;
      myset (chr (235)) := 444;
      myset (chr (236)) := 278;
      myset (chr (237)) := 278;
      myset (chr (238)) := 278;
      myset (chr (239)) := 278;
      myset (chr (240)) := 500;
      myset (chr (241)) := 500;
      myset (chr (242)) := 500;
      myset (chr (243)) := 500;
      myset (chr (244)) := 500;
      myset (chr (245)) := 500;
      myset (chr (246)) := 500;
      myset (chr (247)) := 675;
      myset (chr (248)) := 500;
      myset (chr (249)) := 500;
      myset (chr (250)) := 500;
      myset (chr (251)) := 500;
      myset (chr (252)) := 500;
      myset (chr (253)) := 444;
      myset (chr (254)) := 500;
      myset (chr (255)) := 444;
      return myset;
   end getfonttimesi;

----------------------------------------------------------------------------------
-- Setting metric for times BOLD
----------------------------------------------------------------------------------
   function getfonttimesb
      return charset
   is
      myset       charset;
   begin
      -- Times bold font.
      myset (chr (0)) := 250;
      myset (chr (1)) := 250;
      myset (chr (2)) := 250;
      myset (chr (3)) := 250;
      myset (chr (4)) := 250;
      myset (chr (5)) := 250;
      myset (chr (6)) := 250;
      myset (chr (7)) := 250;
      myset (chr (8)) := 250;
      myset (chr (9)) := 250;
      myset (chr (10)) := 250;
      myset (chr (11)) := 250;
      myset (chr (12)) := 250;
      myset (chr (13)) := 250;
      myset (chr (14)) := 250;
      myset (chr (15)) := 250;
      myset (chr (16)) := 250;
      myset (chr (17)) := 250;
      myset (chr (18)) := 250;
      myset (chr (19)) := 250;
      myset (chr (20)) := 250;
      myset (chr (21)) := 250;
      myset (chr (22)) := 250;
      myset (chr (23)) := 250;
      myset (chr (24)) := 250;
      myset (chr (25)) := 250;
      myset (chr (26)) := 250;
      myset (chr (27)) := 250;
      myset (chr (28)) := 250;
      myset (chr (29)) := 250;
      myset (chr (30)) := 250;
      myset (chr (31)) := 250;
      myset (' ') := 250;
      myset ('!') := 333;
      myset ('"') := 555;
      myset ('#') := 500;
      myset ('$') := 500;
      myset ('%') := 1000;
      myset ('&') := 833;
      myset ('''') := 278;
      myset ('(') := 333;
      myset (')') := 333;
      myset ('*') := 500;
      myset ('+') := 570;
      myset (',') := 250;
      myset ('-') := 333;
      myset ('.') := 250;
      myset ('/') := 278;
      myset ('0') := 500;
      myset ('1') := 500;
      myset ('2') := 500;
      myset ('3') := 500;
      myset ('4') := 500;
      myset ('5') := 500;
      myset ('6') := 500;
      myset ('7') := 500;
      myset ('8') := 500;
      myset ('9') := 500;
      myset (':') := 333;
      myset (';') := 333;
      myset ('<') := 570;
      myset ('=') := 570;
      myset ('>') := 570;
      myset ('?') := 500;
      myset ('@') := 930;
      myset ('A') := 722;
      myset ('B') := 667;
      myset ('C') := 722;
      myset ('D') := 722;
      myset ('E') := 667;
      myset ('F') := 611;
      myset ('G') := 778;
      myset ('H') := 778;
      myset ('I') := 389;
      myset ('J') := 500;
      myset ('K') := 778;
      myset ('L') := 667;
      myset ('M') := 944;
      myset ('N') := 722;
      myset ('O') := 778;
      myset ('P') := 611;
      myset ('Q') := 778;
      myset ('R') := 722;
      myset ('S') := 556;
      myset ('T') := 667;
      myset ('U') := 722;
      myset ('V') := 722;
      myset ('W') := 1000;
      myset ('X') := 722;
      myset ('Y') := 722;
      myset ('Z') := 667;
      myset ('[') := 333;
      myset ('\') := 278;
      myset (']') := 333;
      myset ('^') := 581;
      myset ('_') := 500;
      myset ('`') := 333;
      myset ('a') := 500;
      myset ('b') := 556;
      myset ('c') := 444;
      myset ('d') := 556;
      myset ('e') := 444;
      myset ('f') := 333;
      myset ('g') := 500;
      myset ('h') := 556;
      myset ('i') := 278;
      myset ('j') := 333;
      myset ('k') := 556;
      myset ('l') := 278;
      myset ('m') := 833;
      myset ('n') := 556;
      myset ('o') := 500;
      myset ('p') := 556;
      myset ('q') := 556;
      myset ('r') := 444;
      myset ('s') := 389;
      myset ('t') := 333;
      myset ('u') := 556;
      myset ('v') := 500;
      myset ('w') := 722;
      myset ('x') := 500;
      myset ('y') := 500;
      myset ('z') := 444;
      myset ('{') := 394;
      myset ('|') := 220;
      myset ('}') := 394;
      myset ('~') := 520;
      myset (chr (127)) := 350;
      myset (chr (128)) := 500;
      myset (chr (129)) := 350;
      myset (chr (130)) := 333;
      myset (chr (131)) := 500;
      myset (chr (132)) := 500;
      myset (chr (133)) := 1000;
      myset (chr (134)) := 500;
      myset (chr (135)) := 500;
      myset (chr (136)) := 333;
      myset (chr (137)) := 1000;
      myset (chr (138)) := 556;
      myset (chr (139)) := 333;
      myset (chr (140)) := 1000;
      myset (chr (141)) := 350;
      myset (chr (142)) := 667;
      myset (chr (143)) := 350;
      myset (chr (144)) := 350;
      myset (chr (145)) := 333;
      myset (chr (146)) := 333;
      myset (chr (147)) := 500;
      myset (chr (148)) := 500;
      myset (chr (149)) := 350;
      myset (chr (150)) := 500;
      myset (chr (151)) := 1000;
      myset (chr (152)) := 333;
      myset (chr (153)) := 1000;
      myset (chr (154)) := 389;
      myset (chr (155)) := 333;
      myset (chr (156)) := 722;
      myset (chr (157)) := 350;
      myset (chr (158)) := 444;
      myset (chr (159)) := 722;
      myset (chr (160)) := 250;
      myset (chr (161)) := 333;
      myset (chr (162)) := 500;
      myset (chr (163)) := 500;
      myset (chr (164)) := 500;
      myset (chr (165)) := 500;
      myset (chr (166)) := 220;
      myset (chr (167)) := 500;
      myset (chr (168)) := 333;
      myset (chr (169)) := 747;
      myset (chr (170)) := 300;
      myset (chr (171)) := 500;
      myset (chr (172)) := 570;
      myset (chr (173)) := 333;
      myset (chr (174)) := 747;
      myset (chr (175)) := 333;
      myset (chr (176)) := 400;
      myset (chr (177)) := 570;
      myset (chr (178)) := 300;
      myset (chr (179)) := 300;
      myset (chr (180)) := 333;
      myset (chr (181)) := 556;
      myset (chr (182)) := 540;
      myset (chr (183)) := 250;
      myset (chr (184)) := 333;
      myset (chr (185)) := 300;
      myset (chr (186)) := 330;
      myset (chr (187)) := 500;
      myset (chr (188)) := 750;
      myset (chr (189)) := 750;
      myset (chr (190)) := 750;
      myset (chr (191)) := 500;
      myset (chr (192)) := 722;
      myset (chr (193)) := 722;
      myset (chr (194)) := 722;
      myset (chr (195)) := 722;
      myset (chr (196)) := 722;
      myset (chr (197)) := 722;
      myset (chr (198)) := 1000;
      myset (chr (199)) := 722;
      myset (chr (200)) := 667;
      myset (chr (201)) := 667;
      myset (chr (202)) := 667;
      myset (chr (203)) := 667;
      myset (chr (204)) := 389;
      myset (chr (205)) := 389;
      myset (chr (206)) := 389;
      myset (chr (207)) := 389;
      myset (chr (208)) := 722;
      myset (chr (209)) := 722;
      myset (chr (210)) := 778;
      myset (chr (211)) := 778;
      myset (chr (212)) := 778;
      myset (chr (213)) := 778;
      myset (chr (214)) := 778;
      myset (chr (215)) := 570;
      myset (chr (216)) := 778;
      myset (chr (217)) := 722;
      myset (chr (218)) := 722;
      myset (chr (219)) := 722;
      myset (chr (220)) := 722;
      myset (chr (221)) := 722;
      myset (chr (222)) := 611;
      myset (chr (223)) := 556;
      myset (chr (224)) := 500;
      myset (chr (225)) := 500;
      myset (chr (226)) := 500;
      myset (chr (227)) := 500;
      myset (chr (228)) := 500;
      myset (chr (229)) := 500;
      myset (chr (230)) := 722;
      myset (chr (231)) := 444;
      myset (chr (232)) := 444;
      myset (chr (233)) := 444;
      myset (chr (234)) := 444;
      myset (chr (235)) := 444;
      myset (chr (236)) := 278;
      myset (chr (237)) := 278;
      myset (chr (238)) := 278;
      myset (chr (239)) := 278;
      myset (chr (240)) := 500;
      myset (chr (241)) := 556;
      myset (chr (242)) := 500;
      myset (chr (243)) := 500;
      myset (chr (244)) := 500;
      myset (chr (245)) := 500;
      myset (chr (246)) := 500;
      myset (chr (247)) := 570;
      myset (chr (248)) := 500;
      myset (chr (249)) := 556;
      myset (chr (250)) := 556;
      myset (chr (251)) := 556;
      myset (chr (252)) := 556;
      myset (chr (253)) := 500;
      myset (chr (254)) := 556;
      myset (chr (255)) := 500;
      return myset;
   end getfonttimesb;

----------------------------------------------------------------------------------
-- Setting metric for times BOLD ITALIC
----------------------------------------------------------------------------------
   function getfonttimesbi
      return charset
   is
      myset       charset;
   begin
      -- Times bold italic font.
      myset (chr (0)) := 250;
      myset (chr (1)) := 250;
      myset (chr (2)) := 250;
      myset (chr (3)) := 250;
      myset (chr (4)) := 250;
      myset (chr (5)) := 250;
      myset (chr (6)) := 250;
      myset (chr (7)) := 250;
      myset (chr (8)) := 250;
      myset (chr (9)) := 250;
      myset (chr (10)) := 250;
      myset (chr (11)) := 250;
      myset (chr (12)) := 250;
      myset (chr (13)) := 250;
      myset (chr (14)) := 250;
      myset (chr (15)) := 250;
      myset (chr (16)) := 250;
      myset (chr (17)) := 250;
      myset (chr (18)) := 250;
      myset (chr (19)) := 250;
      myset (chr (20)) := 250;
      myset (chr (21)) := 250;
      myset (chr (22)) := 250;
      myset (chr (23)) := 250;
      myset (chr (24)) := 250;
      myset (chr (25)) := 250;
      myset (chr (26)) := 250;
      myset (chr (27)) := 250;
      myset (chr (28)) := 250;
      myset (chr (29)) := 250;
      myset (chr (30)) := 250;
      myset (chr (31)) := 250;
      myset (' ') := 250;
      myset ('!') := 389;
      myset ('"') := 555;
      myset ('#') := 500;
      myset ('$') := 500;
      myset ('%') := 833;
      myset ('&') := 778;
      myset ('''') := 278;
      myset ('(') := 333;
      myset (')') := 333;
      myset ('*') := 500;
      myset ('+') := 570;
      myset (',') := 250;
      myset ('-') := 333;
      myset ('.') := 250;
      myset ('/') := 278;
      myset ('0') := 500;
      myset ('1') := 500;
      myset ('2') := 500;
      myset ('3') := 500;
      myset ('4') := 500;
      myset ('5') := 500;
      myset ('6') := 500;
      myset ('7') := 500;
      myset ('8') := 500;
      myset ('9') := 500;
      myset (':') := 333;
      myset (';') := 333;
      myset ('<') := 570;
      myset ('=') := 570;
      myset ('>') := 570;
      myset ('?') := 500;
      myset ('@') := 832;
      myset ('A') := 667;
      myset ('B') := 667;
      myset ('C') := 667;
      myset ('D') := 722;
      myset ('E') := 667;
      myset ('F') := 667;
      myset ('G') := 722;
      myset ('H') := 778;
      myset ('I') := 389;
      myset ('J') := 500;
      myset ('K') := 667;
      myset ('L') := 611;
      myset ('M') := 889;
      myset ('N') := 722;
      myset ('O') := 722;
      myset ('P') := 611;
      myset ('Q') := 722;
      myset ('R') := 667;
      myset ('S') := 556;
      myset ('T') := 611;
      myset ('U') := 722;
      myset ('V') := 667;
      myset ('W') := 889;
      myset ('X') := 667;
      myset ('Y') := 611;
      myset ('Z') := 611;
      myset ('[') := 333;
      myset ('\') := 278;
      myset (']') := 333;
      myset ('^') := 570;
      myset ('_') := 500;
      myset ('`') := 333;
      myset ('a') := 500;
      myset ('b') := 500;
      myset ('c') := 444;
      myset ('d') := 500;
      myset ('e') := 444;
      myset ('f') := 333;
      myset ('g') := 500;
      myset ('h') := 556;
      myset ('i') := 278;
      myset ('j') := 278;
      myset ('k') := 500;
      myset ('l') := 278;
      myset ('m') := 778;
      myset ('n') := 556;
      myset ('o') := 500;
      myset ('p') := 500;
      myset ('q') := 500;
      myset ('r') := 389;
      myset ('s') := 389;
      myset ('t') := 278;
      myset ('u') := 556;
      myset ('v') := 444;
      myset ('w') := 667;
      myset ('x') := 500;
      myset ('y') := 444;
      myset ('z') := 389;
      myset ('{') := 348;
      myset ('|') := 220;
      myset ('}') := 348;
      myset ('~') := 570;
      myset (chr (127)) := 350;
      myset (chr (128)) := 500;
      myset (chr (129)) := 350;
      myset (chr (130)) := 333;
      myset (chr (131)) := 500;
      myset (chr (132)) := 500;
      myset (chr (133)) := 1000;
      myset (chr (134)) := 500;
      myset (chr (135)) := 500;
      myset (chr (136)) := 333;
      myset (chr (137)) := 1000;
      myset (chr (138)) := 556;
      myset (chr (139)) := 333;
      myset (chr (140)) := 944;
      myset (chr (141)) := 350;
      myset (chr (142)) := 611;
      myset (chr (143)) := 350;
      myset (chr (144)) := 350;
      myset (chr (145)) := 333;
      myset (chr (146)) := 333;
      myset (chr (147)) := 500;
      myset (chr (148)) := 500;
      myset (chr (149)) := 350;
      myset (chr (150)) := 500;
      myset (chr (151)) := 1000;
      myset (chr (152)) := 333;
      myset (chr (153)) := 1000;
      myset (chr (154)) := 389;
      myset (chr (155)) := 333;
      myset (chr (156)) := 722;
      myset (chr (157)) := 350;
      myset (chr (158)) := 389;
      myset (chr (159)) := 611;
      myset (chr (160)) := 250;
      myset (chr (161)) := 389;
      myset (chr (162)) := 500;
      myset (chr (163)) := 500;
      myset (chr (164)) := 500;
      myset (chr (165)) := 500;
      myset (chr (166)) := 220;
      myset (chr (167)) := 500;
      myset (chr (168)) := 333;
      myset (chr (169)) := 747;
      myset (chr (170)) := 266;
      myset (chr (171)) := 500;
      myset (chr (172)) := 606;
      myset (chr (173)) := 333;
      myset (chr (174)) := 747;
      myset (chr (175)) := 333;
      myset (chr (176)) := 400;
      myset (chr (177)) := 570;
      myset (chr (178)) := 300;
      myset (chr (179)) := 300;
      myset (chr (180)) := 333;
      myset (chr (181)) := 576;
      myset (chr (182)) := 500;
      myset (chr (183)) := 250;
      myset (chr (184)) := 333;
      myset (chr (185)) := 300;
      myset (chr (186)) := 300;
      myset (chr (187)) := 500;
      myset (chr (188)) := 750;
      myset (chr (189)) := 750;
      myset (chr (190)) := 750;
      myset (chr (191)) := 500;
      myset (chr (192)) := 667;
      myset (chr (193)) := 667;
      myset (chr (194)) := 667;
      myset (chr (195)) := 667;
      myset (chr (196)) := 667;
      myset (chr (197)) := 667;
      myset (chr (198)) := 944;
      myset (chr (199)) := 667;
      myset (chr (200)) := 667;
      myset (chr (201)) := 667;
      myset (chr (202)) := 667;
      myset (chr (203)) := 667;
      myset (chr (204)) := 389;
      myset (chr (205)) := 389;
      myset (chr (206)) := 389;
      myset (chr (207)) := 389;
      myset (chr (208)) := 722;
      myset (chr (209)) := 722;
      myset (chr (210)) := 722;
      myset (chr (211)) := 722;
      myset (chr (212)) := 722;
      myset (chr (213)) := 722;
      myset (chr (214)) := 722;
      myset (chr (215)) := 570;
      myset (chr (216)) := 722;
      myset (chr (217)) := 722;
      myset (chr (218)) := 722;
      myset (chr (219)) := 722;
      myset (chr (220)) := 722;
      myset (chr (221)) := 611;
      myset (chr (222)) := 611;
      myset (chr (223)) := 500;
      myset (chr (224)) := 500;
      myset (chr (225)) := 500;
      myset (chr (226)) := 500;
      myset (chr (227)) := 500;
      myset (chr (228)) := 500;
      myset (chr (229)) := 500;
      myset (chr (230)) := 722;
      myset (chr (231)) := 444;
      myset (chr (232)) := 444;
      myset (chr (233)) := 444;
      myset (chr (234)) := 444;
      myset (chr (235)) := 444;
      myset (chr (236)) := 278;
      myset (chr (237)) := 278;
      myset (chr (238)) := 278;
      myset (chr (239)) := 278;
      myset (chr (240)) := 500;
      myset (chr (241)) := 556;
      myset (chr (242)) := 500;
      myset (chr (243)) := 500;
      myset (chr (244)) := 500;
      myset (chr (245)) := 500;
      myset (chr (246)) := 500;
      myset (chr (247)) := 570;
      myset (chr (248)) := 500;
      myset (chr (249)) := 556;
      myset (chr (250)) := 556;
      myset (chr (251)) := 556;
      myset (chr (252)) := 556;
      myset (chr (253)) := 444;
      myset (chr (254)) := 500;
      myset (chr (255)) := 444;
      return myset;
   end getfonttimesbi;

----------------------------------------------------------------------------------
-- Setting metric for Symbol
----------------------------------------------------------------------------------
   function getfontsymbol
      return charset
   is
      myset       charset;
   begin
      -- Symbol font.
      myset (chr (0)) := 250;
      myset (chr (1)) := 250;
      myset (chr (2)) := 250;
      myset (chr (3)) := 250;
      myset (chr (4)) := 250;
      myset (chr (5)) := 250;
      myset (chr (6)) := 250;
      myset (chr (7)) := 250;
      myset (chr (8)) := 250;
      myset (chr (9)) := 250;
      myset (chr (10)) := 250;
      myset (chr (11)) := 250;
      myset (chr (12)) := 250;
      myset (chr (13)) := 250;
      myset (chr (14)) := 250;
      myset (chr (15)) := 250;
      myset (chr (16)) := 250;
      myset (chr (17)) := 250;
      myset (chr (18)) := 250;
      myset (chr (19)) := 250;
      myset (chr (20)) := 250;
      myset (chr (21)) := 250;
      myset (chr (22)) := 250;
      myset (chr (23)) := 250;
      myset (chr (24)) := 250;
      myset (chr (25)) := 250;
      myset (chr (26)) := 250;
      myset (chr (27)) := 250;
      myset (chr (28)) := 250;
      myset (chr (29)) := 250;
      myset (chr (30)) := 250;
      myset (chr (31)) := 250;
      myset (' ') := 250;
      myset ('!') := 333;
      myset ('"') := 713;
      myset ('#') := 500;
      myset ('$') := 549;
      myset ('%') := 833;
      myset ('&') := 778;
      myset ('''') := 439;
      myset ('(') := 333;
      myset (')') := 333;
      myset ('*') := 500;
      myset ('+') := 549;
      myset (',') := 250;
      myset ('-') := 549;
      myset ('.') := 250;
      myset ('/') := 278;
      myset ('0') := 500;
      myset ('1') := 500;
      myset ('2') := 500;
      myset ('3') := 500;
      myset ('4') := 500;
      myset ('5') := 500;
      myset ('6') := 500;
      myset ('7') := 500;
      myset ('8') := 500;
      myset ('9') := 500;
      myset (':') := 278;
      myset (';') := 278;
      myset ('<') := 549;
      myset ('=') := 549;
      myset ('>') := 549;
      myset ('?') := 444;
      myset ('@') := 549;
      myset ('A') := 722;
      myset ('B') := 667;
      myset ('C') := 722;
      myset ('D') := 612;
      myset ('E') := 611;
      myset ('F') := 763;
      myset ('G') := 603;
      myset ('H') := 722;
      myset ('I') := 333;
      myset ('J') := 631;
      myset ('K') := 722;
      myset ('L') := 686;
      myset ('M') := 889;
      myset ('N') := 722;
      myset ('O') := 722;
      myset ('P') := 768;
      myset ('Q') := 741;
      myset ('R') := 556;
      myset ('S') := 592;
      myset ('T') := 611;
      myset ('U') := 690;
      myset ('V') := 439;
      myset ('W') := 768;
      myset ('X') := 645;
      myset ('Y') := 795;
      myset ('Z') := 611;
      myset ('[') := 333;
      myset ('\') := 863;
      myset (']') := 333;
      myset ('^') := 658;
      myset ('_') := 500;
      myset ('`') := 500;
      myset ('a') := 631;
      myset ('b') := 549;
      myset ('c') := 549;
      myset ('d') := 494;
      myset ('e') := 439;
      myset ('f') := 521;
      myset ('g') := 411;
      myset ('h') := 603;
      myset ('i') := 329;
      myset ('j') := 603;
      myset ('k') := 549;
      myset ('l') := 549;
      myset ('m') := 576;
      myset ('n') := 521;
      myset ('o') := 549;
      myset ('p') := 549;
      myset ('q') := 521;
      myset ('r') := 549;
      myset ('s') := 603;
      myset ('t') := 439;
      myset ('u') := 576;
      myset ('v') := 713;
      myset ('w') := 686;
      myset ('x') := 493;
      myset ('y') := 686;
      myset ('z') := 494;
      myset ('{') := 480;
      myset ('|') := 200;
      myset ('}') := 480;
      myset ('~') := 549;
      myset (chr (127)) := 0;
      myset (chr (128)) := 0;
      myset (chr (129)) := 0;
      myset (chr (130)) := 0;
      myset (chr (131)) := 0;
      myset (chr (132)) := 0;
      myset (chr (133)) := 0;
      myset (chr (134)) := 0;
      myset (chr (135)) := 0;
      myset (chr (136)) := 0;
      myset (chr (137)) := 0;
      myset (chr (138)) := 0;
      myset (chr (139)) := 0;
      myset (chr (140)) := 0;
      myset (chr (141)) := 0;
      myset (chr (142)) := 0;
      myset (chr (143)) := 0;
      myset (chr (144)) := 0;
      myset (chr (145)) := 0;
      myset (chr (146)) := 0;
      myset (chr (147)) := 0;
      myset (chr (148)) := 0;
      myset (chr (149)) := 0;
      myset (chr (150)) := 0;
      myset (chr (151)) := 0;
      myset (chr (152)) := 0;
      myset (chr (153)) := 0;
      myset (chr (154)) := 0;
      myset (chr (155)) := 0;
      myset (chr (156)) := 0;
      myset (chr (157)) := 0;
      myset (chr (158)) := 0;
      myset (chr (159)) := 0;
      myset (chr (160)) := 750;
      myset (chr (161)) := 620;
      myset (chr (162)) := 247;
      myset (chr (163)) := 549;
      myset (chr (164)) := 167;
      myset (chr (165)) := 713;
      myset (chr (166)) := 500;
      myset (chr (167)) := 753;
      myset (chr (168)) := 753;
      myset (chr (169)) := 753;
      myset (chr (170)) := 753;
      myset (chr (171)) := 1042;
      myset (chr (172)) := 987;
      myset (chr (173)) := 603;
      myset (chr (174)) := 987;
      myset (chr (175)) := 603;
      myset (chr (176)) := 400;
      myset (chr (177)) := 549;
      myset (chr (178)) := 411;
      myset (chr (179)) := 549;
      myset (chr (180)) := 549;
      myset (chr (181)) := 713;
      myset (chr (182)) := 494;
      myset (chr (183)) := 460;
      myset (chr (184)) := 549;
      myset (chr (185)) := 549;
      myset (chr (186)) := 549;
      myset (chr (187)) := 549;
      myset (chr (188)) := 1000;
      myset (chr (189)) := 603;
      myset (chr (190)) := 1000;
      myset (chr (191)) := 658;
      myset (chr (192)) := 823;
      myset (chr (193)) := 686;
      myset (chr (194)) := 795;
      myset (chr (195)) := 987;
      myset (chr (196)) := 768;
      myset (chr (197)) := 768;
      myset (chr (198)) := 823;
      myset (chr (199)) := 768;
      myset (chr (200)) := 768;
      myset (chr (201)) := 713;
      myset (chr (202)) := 713;
      myset (chr (203)) := 713;
      myset (chr (204)) := 713;
      myset (chr (205)) := 713;
      myset (chr (206)) := 713;
      myset (chr (207)) := 713;
      myset (chr (208)) := 768;
      myset (chr (209)) := 713;
      myset (chr (210)) := 790;
      myset (chr (211)) := 790;
      myset (chr (212)) := 890;
      myset (chr (213)) := 823;
      myset (chr (214)) := 549;
      myset (chr (215)) := 250;
      myset (chr (216)) := 713;
      myset (chr (217)) := 603;
      myset (chr (218)) := 603;
      myset (chr (219)) := 1042;
      myset (chr (220)) := 987;
      myset (chr (221)) := 603;
      myset (chr (222)) := 987;
      myset (chr (223)) := 603;
      myset (chr (224)) := 494;
      myset (chr (225)) := 329;
      myset (chr (226)) := 790;
      myset (chr (227)) := 790;
      myset (chr (228)) := 786;
      myset (chr (229)) := 713;
      myset (chr (230)) := 384;
      myset (chr (231)) := 384;
      myset (chr (232)) := 384;
      myset (chr (233)) := 384;
      myset (chr (234)) := 384;
      myset (chr (235)) := 384;
      myset (chr (236)) := 494;
      myset (chr (237)) := 494;
      myset (chr (238)) := 494;
      myset (chr (239)) := 494;
      myset (chr (240)) := 0;
      myset (chr (241)) := 329;
      myset (chr (242)) := 274;
      myset (chr (243)) := 686;
      myset (chr (244)) := 686;
      myset (chr (245)) := 686;
      myset (chr (246)) := 384;
      myset (chr (247)) := 384;
      myset (chr (248)) := 384;
      myset (chr (249)) := 384;
      myset (chr (250)) := 384;
      myset (chr (251)) := 384;
      myset (chr (252)) := 494;
      myset (chr (253)) := 494;
      myset (chr (254)) := 494;
      myset (chr (255)) := 0;
      return myset;
   end getfontsymbol;

----------------------------------------------------------------------------------
-- Setting metric for zapfdingbats
----------------------------------------------------------------------------------
   function getfontzapfdingbats
      return charset
   is
      myset       charset;
   begin
      -- zapfdingbats font.
      myset (chr (0)) := 0;
      myset (chr (1)) := 0;
      myset (chr (2)) := 0;
      myset (chr (3)) := 0;
      myset (chr (4)) := 0;
      myset (chr (5)) := 0;
      myset (chr (6)) := 0;
      myset (chr (7)) := 0;
      myset (chr (8)) := 0;
      myset (chr (9)) := 0;
      myset (chr (10)) := 0;
      myset (chr (11)) := 0;
      myset (chr (12)) := 0;
      myset (chr (13)) := 0;
      myset (chr (14)) := 0;
      myset (chr (15)) := 0;
      myset (chr (16)) := 0;
      myset (chr (17)) := 0;
      myset (chr (18)) := 0;
      myset (chr (19)) := 0;
      myset (chr (20)) := 0;
      myset (chr (21)) := 0;
      myset (chr (22)) := 0;
      myset (chr (23)) := 0;
      myset (chr (24)) := 0;
      myset (chr (25)) := 0;
      myset (chr (26)) := 0;
      myset (chr (27)) := 0;
      myset (chr (28)) := 0;
      myset (chr (29)) := 0;
      myset (chr (30)) := 0;
      myset (chr (31)) := 0;
      myset (' ') := 278;
      myset ('!') := 974;
      myset ('"') := 961;
      myset ('#') := 974;
      myset ('$') := 980;
      myset ('%') := 719;
      myset ('&') := 789;
      myset ('''') := 790;
      myset ('(') := 791;
      myset (')') := 690;
      myset ('*') := 960;
      myset ('+') := 939;
      myset (',') := 549;
      myset ('-') := 855;
      myset ('.') := 911;
      myset ('/') := 933;
      myset ('0') := 911;
      myset ('1') := 945;
      myset ('2') := 974;
      myset ('3') := 755;
      myset ('4') := 846;
      myset ('5') := 762;
      myset ('6') := 761;
      myset ('7') := 571;
      myset ('8') := 677;
      myset ('9') := 763;
      myset (':') := 760;
      myset (';') := 759;
      myset ('<') := 754;
      myset ('=') := 494;
      myset ('>') := 552;
      myset ('?') := 537;
      myset ('@') := 577;
      myset ('A') := 692;
      myset ('B') := 786;
      myset ('C') := 788;
      myset ('D') := 788;
      myset ('E') := 790;
      myset ('F') := 793;
      myset ('G') := 794;
      myset ('H') := 816;
      myset ('I') := 823;
      myset ('J') := 789;
      myset ('K') := 841;
      myset ('L') := 823;
      myset ('M') := 833;
      myset ('N') := 816;
      myset ('O') := 831;
      myset ('P') := 923;
      myset ('Q') := 744;
      myset ('R') := 723;
      myset ('S') := 749;
      myset ('T') := 790;
      myset ('U') := 792;
      myset ('V') := 695;
      myset ('W') := 776;
      myset ('X') := 768;
      myset ('Y') := 792;
      myset ('Z') := 759;
      myset ('[') := 707;
      myset ('\') := 708;
      myset (']') := 682;
      myset ('^') := 701;
      myset ('_') := 826;
      myset ('`') := 815;
      myset ('a') := 789;
      myset ('b') := 789;
      myset ('c') := 707;
      myset ('d') := 687;
      myset ('e') := 696;
      myset ('f') := 689;
      myset ('g') := 786;
      myset ('h') := 787;
      myset ('i') := 713;
      myset ('j') := 791;
      myset ('k') := 785;
      myset ('l') := 791;
      myset ('m') := 873;
      myset ('n') := 761;
      myset ('o') := 762;
      myset ('p') := 762;
      myset ('q') := 759;
      myset ('r') := 759;
      myset ('s') := 892;
      myset ('t') := 892;
      myset ('u') := 788;
      myset ('v') := 784;
      myset ('w') := 438;
      myset ('x') := 138;
      myset ('y') := 277;
      myset ('z') := 415;
      myset ('{') := 392;
      myset ('|') := 392;
      myset ('}') := 668;
      myset ('~') := 668;
      myset (chr (127)) := 0;
      myset (chr (128)) := 390;
      myset (chr (129)) := 390;
      myset (chr (130)) := 317;
      myset (chr (131)) := 317;
      myset (chr (132)) := 276;
      myset (chr (133)) := 276;
      myset (chr (134)) := 509;
      myset (chr (135)) := 509;
      myset (chr (136)) := 410;
      myset (chr (137)) := 410;
      myset (chr (138)) := 234;
      myset (chr (139)) := 234;
      myset (chr (140)) := 334;
      myset (chr (141)) := 334;
      myset (chr (142)) := 0;
      myset (chr (143)) := 0;
      myset (chr (144)) := 0;
      myset (chr (145)) := 0;
      myset (chr (146)) := 0;
      myset (chr (147)) := 0;
      myset (chr (148)) := 0;
      myset (chr (149)) := 0;
      myset (chr (150)) := 0;
      myset (chr (151)) := 0;
      myset (chr (152)) := 0;
      myset (chr (153)) := 0;
      myset (chr (154)) := 0;
      myset (chr (155)) := 0;
      myset (chr (156)) := 0;
      myset (chr (157)) := 0;
      myset (chr (158)) := 0;
      myset (chr (159)) := 0;
      myset (chr (160)) := 0;
      myset (chr (161)) := 732;
      myset (chr (162)) := 544;
      myset (chr (163)) := 544;
      myset (chr (164)) := 910;
      myset (chr (165)) := 667;
      myset (chr (166)) := 760;
      myset (chr (167)) := 760;
      myset (chr (168)) := 776;
      myset (chr (169)) := 595;
      myset (chr (170)) := 694;
      myset (chr (171)) := 626;
      myset (chr (172)) := 788;
      myset (chr (173)) := 788;
      myset (chr (174)) := 788;
      myset (chr (175)) := 788;
      myset (chr (176)) := 788;
      myset (chr (177)) := 788;
      myset (chr (178)) := 788;
      myset (chr (179)) := 788;
      myset (chr (180)) := 788;
      myset (chr (181)) := 788;
      myset (chr (182)) := 788;
      myset (chr (183)) := 788;
      myset (chr (184)) := 788;
      myset (chr (185)) := 788;
      myset (chr (186)) := 788;
      myset (chr (187)) := 788;
      myset (chr (188)) := 788;
      myset (chr (189)) := 788;
      myset (chr (190)) := 788;
      myset (chr (191)) := 788;
      myset (chr (192)) := 788;
      myset (chr (193)) := 788;
      myset (chr (194)) := 788;
      myset (chr (195)) := 788;
      myset (chr (196)) := 788;
      myset (chr (197)) := 788;
      myset (chr (198)) := 788;
      myset (chr (199)) := 788;
      myset (chr (200)) := 788;
      myset (chr (201)) := 788;
      myset (chr (202)) := 788;
      myset (chr (203)) := 788;
      myset (chr (204)) := 788;
      myset (chr (205)) := 788;
      myset (chr (206)) := 788;
      myset (chr (207)) := 788;
      myset (chr (208)) := 788;
      myset (chr (209)) := 788;
      myset (chr (210)) := 788;
      myset (chr (211)) := 788;
      myset (chr (212)) := 894;
      myset (chr (213)) := 838;
      myset (chr (214)) := 1016;
      myset (chr (215)) := 458;
      myset (chr (216)) := 748;
      myset (chr (217)) := 924;
      myset (chr (218)) := 748;
      myset (chr (219)) := 918;
      myset (chr (220)) := 927;
      myset (chr (221)) := 928;
      myset (chr (222)) := 928;
      myset (chr (223)) := 834;
      myset (chr (224)) := 873;
      myset (chr (225)) := 828;
      myset (chr (226)) := 924;
      myset (chr (227)) := 924;
      myset (chr (228)) := 917;
      myset (chr (229)) := 930;
      myset (chr (230)) := 931;
      myset (chr (231)) := 463;
      myset (chr (232)) := 883;
      myset (chr (233)) := 836;
      myset (chr (234)) := 836;
      myset (chr (235)) := 867;
      myset (chr (236)) := 867;
      myset (chr (237)) := 696;
      myset (chr (238)) := 696;
      myset (chr (239)) := 874;
      myset (chr (240)) := 0;
      myset (chr (241)) := 874;
      myset (chr (242)) := 760;
      myset (chr (243)) := 946;
      myset (chr (244)) := 771;
      myset (chr (245)) := 865;
      myset (chr (246)) := 771;
      myset (chr (247)) := 888;
      myset (chr (248)) := 967;
      myset (chr (249)) := 888;
      myset (chr (250)) := 831;
      myset (chr (251)) := 873;
      myset (chr (252)) := 927;
      myset (chr (253)) := 970;
      myset (chr (254)) := 918;
      myset (chr (255)) := 0;
      return myset;
   end getfontzapfdingbats;

----------------------------------------------------------------------------------
-- Inclusion des métriques d'une font.
----------------------------------------------------------------------------------
   procedure p_includefont ( pfontname varchar2 )
   is
      myset                         charset;
   begin
      if (pfontname is not null)
      then
         case pfontname
         when 'courier'
         then -- courier
            myset := getfontcourier;
            pdf_charwidths (pfontname || 'B') := myset;
            pdf_charwidths (pfontname || 'I') := myset;
            pdf_charwidths (pfontname || 'BI') := myset;
         when 'helvetica'
         then -- helvetica font.
            myset := getfonthelvetica;
         when 'helveticaI'
         then -- helvetica italic font.
            myset := getfonthelveticai;
         when 'helveticaB'
         then -- helvetica bold font.
            myset := getfonthelveticab;
         when 'helveticaBI'
         then -- helvetica bold italic font.
            myset := getfonthelveticabi;
         when 'times'
         then -- times font.
            myset := getfonttimes;
         when 'timesI'
         then -- times italic font.
            myset := getfonttimesi;
         when 'timesB'
         then -- times bold font.
            myset := getfonttimesb;
         when 'timesBI'
         then -- times bold italic font.
            myset := getfonttimesbi;
         when 'symbol'
         then -- symbol font.
            myset := getfontsymbol;
         when 'zapfdingbats'
         then -- zapfdingbats font.
            myset := getfontzapfdingbats;
         else
            null;
         end case;

         pdf_charwidths (pfontname) := myset;
      end if;
   end p_includefont;

----------------------------------------------------------------------------------
-- p_getFontMetrics : récupérer les metric d'une font.
----------------------------------------------------------------------------------
   function p_getfontmetrics (
      pfontname    varchar2
   )
      return charset
   is
      myset  charset;
   begin
      if (pfontname is not null)
      then
         case pfontname
         when 'courier'
         then -- courier
            myset := getfontcourier;
         when 'helvetica'
         then -- helvetica font.
            myset := getfonthelvetica;
         when 'helveticaI'
         then -- helvetica italic font.
            myset := getfonthelveticai;
         when 'helveticaB'
         then -- helvetica bold font.
            myset := getfonthelveticab;
         when 'helveticaBI'
         then -- helvetica bold italic font.
            myset := getfonthelveticabi;
         when 'times'
         then -- times font.
            myset := getfonttimes;
         when 'timesI'
         then -- times italic font.
            myset := getfonttimesi;
         when 'timesI'
         then -- times bold font.
            myset := getfonttimesb;
         when 'timesBI'
         then -- times bold italic font.
            myset := getfonttimesbi;
         when 'symbol'
         then -- symbol font.
            myset := getfontsymbol;
         when 'zapfdingbats'
         then -- zapfdingbats font.
            myset := getfontzapfdingbats;
         else
            null;
         end case;
      end if;

      return myset;
   end p_getfontmetrics;

----------------------------------------------------------------------------------
-- Parcours le tableau des images et renvoie true si l'image cherché existe
-- dans le tableau.
----------------------------------------------------------------------------------
   function imageexists ( pfile varchar2 )
      return boolean
   is
   begin
      if (images.exists (lower (pfile)))
      then
         return true;
      end if;

      return false;
   exception
      when others
      then
         error ('imageExists : ' || sqlerrm);
         return false;
   end imageexists;

----------------------------------------------------------------------------------
-- Parcours le tableau des charwidths et renvoie true si il existe pour la font
-- donnée.
----------------------------------------------------------------------------------
   function pdf_charwidthsexists ( pfontname varchar2 )
      return boolean
   is
      chtab  charset;
   begin
      if (pdf_charwidths.exists (pfontname))
      then
         chtab := pdf_charwidths (pfontname);

         if (nvl (chtab.count, 0) > 0)
         then
            return true;
         end if;
      end if;

      return false;
   exception
      when others
      then
         return false;
   end pdf_charwidthsexists;

----------------------------------------------------------------------------------
-- Parcours le tableau des fonts et renvoie true si il existe pour la font
-- donnée.
----------------------------------------------------------------------------------
   function fontsexists ( pfontname    varchar2 )
      return boolean
   is
      ft word;
   begin
      if (fonts.exists (pfontname))
      then
         ft := fonts (pfontname).name || fonts (pfontname).type;

         if (nvl (ft, 0) != 0)
         then
            return true;
         end if;
      end if;

      return false;
   exception
      when others
      then
         return false;
   end fontsexists;

--------------------------------------------------------------------------------
-- get an image in a blob from an http url.
-- The image is converted  on the fly to PNG format.
--------------------------------------------------------------------------------
   function getimagefromurl ( p_url varchar2 )
      return ordsys.ordimage
   is
      myimg  ordsys.ordimage;
      lv_url varchar2 (2000) := p_url;
      urityp uritype;
   begin
      -- normalize url.
      if (instr (lv_url, 'http') = 0)
      then
         lv_url :=
              'http://' || owa_util.get_cgi_env ('SERVER_NAME') || '/'
              || lv_url;
      end if;

      urityp := urifactory.geturi (lv_url);
      myimg := ordsys.ordimage.init ();
      myimg.source.localdata := urityp.getblob ();
      myimg.setmimetype (urityp.getcontenttype ());

      begin
         myimg.setproperties ();
      exception
         when others
         then
            null;                     -- Ignore exceptions, mimetype is enough.
      end;

      -- Transform image to PNG if it is a GIF, a JPG or a BMP
      if (myimg.getfileformat () != 'PNGF')
      then
         myimg.process ('fileFormat=PNGF,contentFormat=8bitlutrgb');
         myimg.setproperties ();
      end if;

      return myimg;
   exception
      when others
      then
         error ('getImageFromUrl :' || sqlerrm || ', image :' || p_url);
         return myimg;
         return myimg;
   end getimagefromurl;

--------------------------------------------------------------------------------
-- get an image in a blob from an oracle table.
--------------------------------------------------------------------------------
   function getimagefromdatabase ( pfile varchar2 )
      return ordsys.ordimage
   is
      myimg ordsys.ordimage := ordsys.ordimage.init ();
   begin
      return myimg;
   end getimagefromdatabase;

--------------------------------------------------------------------------------
-- Enables debug infos
--------------------------------------------------------------------------------
   procedure debugenabled
   is
   begin
      gb_mode_debug := true;
   end debugenabled;

--------------------------------------------------------------------------------
-- disables debug infos
--------------------------------------------------------------------------------
   procedure debugdisabled
   is
   begin
      gb_mode_debug := false;
   end debugdisabled;

--------------------------------------------------------------------------------
-- Returns the k property
--------------------------------------------------------------------------------
   function getscalefactor
      return number
   is
   begin
      -- Get scale factor
      return k;
   end getscalefactor;

--------------------------------------------------------------------------------
-- Returns the Linespacing property
--------------------------------------------------------------------------------
   function getlinespacing
      return number
   is
   begin
      -- Get LineSpacing property
      return linespacing;
   end getlinespacing;

--------------------------------------------------------------------------------
-- sets the Linespacing property
--------------------------------------------------------------------------------
   procedure setlinespacing ( pls number )
   is
   begin
      -- Set LineSpacing property
      linespacing := pls;
   end setlinespacing;

   function ord ( pstr varchar2 )
      return number
   is
   begin
      return ascii (substr (pstr, 1, 1));
   end ord;

   function empty ( p_myvar varchar2 )
      return boolean
   is
   begin
      if (p_myvar is null)
      then
         return true;
      end if;

      return false;
   end empty;

   function empty ( p_mynum number )
      return boolean
   is
   begin
      return empty (p_myvar => to_char (p_mynum));
   end empty;

   function str_replace (
      psearch  varchar2
    , preplace varchar2
    , psubject varchar2
   )
      return varchar2
   is
   begin
      return replace (psubject, psearch, preplace);
   end str_replace;

   function strlen ( pstr varchar2 )
      return number
   is
   begin
      return length (pstr);
   end strlen;

   function tonumber ( v_str in varchar2 )
      return number
   is
      v_num  number;
      v_str2 varchar2 (255);
   begin
      begin
         v_num := to_number (v_str);
      exception
         when others
         then
            v_num := null;
      end;

      if v_num is null
      then
         -- maybe wrong NLS, try again
         v_str2 := replace (v_str, ',.', '.,');

         begin
            v_num := to_number (v_str2);
         exception
            when others
            then
               v_num := null;
         end;
      end if;

      return v_num;
   end;

   function tochar (
      pnum        number
    , pprecision  number default 2
   )
      return varchar2
   is
      mynum   word := replace (to_char (pnum), ',', '.');
      ceilnum word;
      decnum  word;
   begin
      if (instr (mynum, '.') = 0)
      then
         mynum := mynum || '.0';
      end if;

      ceilnum := nvl (substr (mynum, 1, instr (mynum, '.') - 1), '0');
      decnum := nvl (substr (mynum, instr (mynum, '.') + 1), '0');
      decnum := substr (decnum, 1, pprecision);

      if (pprecision = 0)
      then
         mynum := ceilnum;
      else
         mynum := ceilnum || '.' || decnum;
      end if;

      return mynum;
   end tochar;

   function date_ymdhis ( p_date date default sysdate )
      return varchar2
   is
   begin
      return to_char (p_date, 'YYYYMMDDHH24MISS');
   end date_ymdhis;

   function is_string ( pstr varchar2 )
      return boolean
   is
      temp varchar2 (2000);
   begin
      temp := to_number (pstr);
      -- if you can change the string to a number it is not a number
      return false;
   exception
      when others
      then
         return true;
   end is_string;

   function function_exists ( pname varchar2 )
      return boolean
   is
   begin
      return false;
   end function_exists;

   function strtoupper ( pstr in out   varchar2 )
      return varchar2
   is
   begin
      return upper (pstr);
   end strtoupper;

   function strtolower ( pstr in out   varchar2 )
      return varchar2
   is
   begin
      return lower (pstr);
   end strtolower;

   function substr_count (
      ptxt varchar2
    , pstr varchar2
   )
      return number
   is
      nbr number := 0;
   begin
      for i in 1 .. length (ptxt)
      loop
         if (substr (ptxt, i, 1) = pstr)
         then
            nbr := nbr + 1;
         end if;
      end loop;

      return nbr;
   end substr_count;

----------------------------------------------------------------------------------------
--  Traduction des méthodes PHP.
----------------------------------------------------------------------------------------
   procedure p_dochecks
   is
   begin
      -- Check for decimal separator
      execute immediate 'alter session set NLS_NUMERIC_CHARACTERS = '',.''';
   end p_dochecks;

----------------------------------------------------------------------------------------
   function p_getfontpath
      return varchar2
   is
   begin
      return null;
   end p_getfontpath;

----------------------------------------------------------------------------------------
   procedure p_out (
      pstr  varchar2 default null
    , pcrlf boolean default true
   )
   is
      lv_crlf varchar2 (2) := null;
   begin
      if (pcrlf)
      then
         lv_crlf := chr (10);
      end if;

      -- Add a line to the document
      if (state = 2)
      then
         pages (page) := pages (page) || pstr || lv_crlf;
      else
         pdfdoc (pdfdoc.last + 1) := pstr || lv_crlf;
      end if;
   exception
      when others
      then
         error ('p_out : ' || sqlerrm);
   end p_out;

----------------------------------------------------------------------------------------
   procedure p_newobj
   is
   begin
      -- Begin a new object
      n := n + 1;
      offsets (n) := getpdfdoclength ();
      p_out (n || ' 0 obj');
   exception
      when others
      then
         error ('p_newobj : ' || sqlerrm);
   end p_newobj;

----------------------------------------------------------------------------------------
   function p_escape ( pstr varchar2 )
      return varchar2
   is
   begin
      -- Add \ before \, ( and )
      return str_replace (')'
                        , '\)'
                        , str_replace ('?'
                                     , '\?'
                                     , str_replace ('('
                                                  , '\('
                                                  , str_replace ('\', '\\'
                                                               , pstr)
                                                   )
                                      )
                         );
   end p_escape;

----------------------------------------------------------------------------------------
   function p_textstring (
      pstr                                varchar2
   )
      return varchar2
   is
   begin
      -- Format a text string
      return '(' || p_escape (pstr) || ')';
   end p_textstring;

----------------------------------------------------------------------------------------
   procedure p_putstream (
      pstr                                varchar2
   )
   is
   begin
      p_out ('stream');
      p_out (pstr);
      p_out ('endstream');
   exception
      when others
      then
         error ('p_putstream : ' || sqlerrm);
   end p_putstream;

----------------------------------------------------------------------------------------
   procedure p_putstream (
      pdata                      in out nocopy blob
   )
   is
      offset                        integer := 1;
      lv_content_length             number := dbms_lob.getlength (pdata);
      buf_size                      integer := 2000;
      buf                           raw (2000);
   begin
      p_out ('stream');

      -- read the blob and put it in small pieces in a varchar
      while offset < lv_content_length
      loop
         dbms_lob.read (pdata, buf_size, offset, buf);
         p_out (utl_raw.cast_to_varchar2 (buf), false);
         offset := offset + buf_size;
      end loop;

      -- put a CRLF at the end of the blob
      p_out (chr (10), false);
      p_out ('endstream');
   exception
      when others
      then
         error ('p_putstream : ' || sqlerrm);
   end p_putstream;

----------------------------------------------------------------------------------------
   procedure p_putxobjectdict
   is
      v txt;
   begin
      v := images.first;

      while (v is not null)
      loop
         p_out ('/I' || images (v).i || ' ' || images (v).n || ' 0 R');
         v := images.next (v);
      end loop;
   exception
      when others
      then
         error ('p_putxobjectdict : ' || sqlerrm);
   end p_putxobjectdict;

----------------------------------------------------------------------------------------
   procedure p_putresourcedict
   is
      v                             varchar2 (200);
   begin
      p_out ('/ProcSet [/PDF /Text /ImageB /ImageC /ImageI]');
      p_out ('/Font <<');
      v := fonts.first;

      while (v is not null)
      loop
         p_out ('/F' || fonts (v).i || ' ' || fonts (v).n || ' 0 R');
         v := fonts.next (v);
      end loop;

      p_out ('>>');
      p_out ('/XObject <<');
      p_putxobjectdict ();
      p_out ('>>');
   exception
      when others
      then
         error ('p_putresourcedict : ' || sqlerrm);
   end p_putresourcedict;

----------------------------------------------------------------------------------------
   procedure p_putfonts
   is
      nf                            number := n;
      i                             pls_integer;
      k                             varchar2 (200);
      v                             varchar2 (200);
      myfont                        varchar2 (2000);
      myset                         charset;
      myheader                      boolean;
      mytype                        word;
      myname                        word;
      myfile                        word;
      s                             varchar2 (2000);
      cw                            charset;
      thetype                       word;
      methode                       word;
-- plsqlmethode word;
   begin
      null;
      i := diffs.first;

      while (i is not null)
      loop
         -- Encodings
         p_newobj ();
         p_out
            (   '<</Type /Encoding /BaseEncoding /WinAnsiEncoding /Differences ['
             || diffs (i)
             || ']>>'
            );
         p_out ('endobj');
         i := diffs.next (i);
      end loop;

      -- foreach($this->FontFiles as $file=>$info)
      v := fontfiles.first;

      while (v is not null)
      loop
         null;
         -- Font file embedding
         p_newobj ();
         fontfiles (v).n := n;
         myfont := null;
         myset := p_getfontmetrics (fontfiles (v).file);

         for i in myset.first .. myset.last
         loop
            myfont := myfont || myset (i);
         end loop;

         if (myset.count = 0)
         then
            error ('Font file not found');
         end if;

         if (fontfiles (v).length2 is not null)
         then
            myheader := false;

            if (ord (myfont) = 128)
            then
               myheader := true;
            end if;

            if (myheader)
            then
               -- Strip first binary header
               myfont := substr (myfont, 6);
            end if;

            if (    myheader
                and ord (substr (myfont, (fontfiles (v).length1), 1)) = 128
               )
            then
               -- Strip second binary header
               myfont :=
                     substr (myfont, 1, fontfiles (v).length1)
                  || substr (myfont, fontfiles (v).length1 + 6);
            end if;
         end if;

         p_out ('<</Length ' || strlen (myfont));
         p_out ('/Length1 ' || fontfiles (v).length1);

         if (fontfiles (v).length2 is not null)
         then
            p_out ('/Length2 ' || fontfiles (v).length2 || ' /Length3 0');
         end if;

         p_out ('>>');
         p_putstream (myfont);
         p_out ('endobj');
         v := fontfiles.next (v);
      end loop;

      k := fonts.first;

      while (k is not null)
      loop
         -- Font objects
         fonts (k).n := n + 1;
         mytype := fonts (k).type;
         myname := fonts (k).name;

         if (mytype = 'core')
         then
            -- Standard font
            p_newobj ();
            p_out ('<</Type /Font');
            p_out ('/BaseFont /' || myname);
            p_out ('/Subtype /Type1');

            if (lower (myname) != 'symbol' and lower (myname) != 'zapfdingbats'
               )
            then
               p_out ('/Encoding /WinAnsiEncoding');
            end if;

            p_out ('>>');
            p_out ('endobj');
         elsif (lower (mytype) = 'type1' or lower (mytype) = 'truetype')
         then
            -- Additional Type1 or TrueType font
            p_newobj ();
            p_out ('<</Type /Font');
            p_out ('/BaseFont /' || myname);
            p_out ('/Subtype /' || mytype);
            p_out ('/FirstChar 32 /LastChar 255');
            p_out ('/Widths ' || (n + 1) || ' 0 R');
            p_out ('/FontDescriptor ' || (n + 2) || ' 0 R');

            if (fonts (k).enc is not null)
            then
               if (fonts (k).diff is not null)
               then
                  p_out ('/Encoding ' || (nf + fonts (k).diff) || ' 0 R');
               else
                  p_out ('/Encoding /WinAnsiEncoding');
               end if;
            end if;

            p_out ('>>');
            p_out ('endobj');
            -- Widths
            p_newobj ();
            cw := fonts (k).cw;
            s := '[';

            for i in 32 .. 255
            loop
               s := s || cw (chr (i)) || ' ';
            end loop;

            p_out (s || ']');
            p_out ('endobj');
            -- Descriptor
            p_newobj ();
            s := '<</Type /FontDescriptor /FontName /' || myname;

            for l in fonts (k).dsc.first .. fonts (k).dsc.last
            loop
               s :=  s || ' /' || l || ' ' || fonts (k).dsc (l);
            end loop;

            myfile := fonts (k).file;

            if (myfile is not null)
            then
               if (lower (mytype) = 'type1')
               then
                  thetype := '';
               else
                  thetype := '2';
               end if;

               s := s
                 || ' /FontFile'
                 || thetype
                 || ' '
                 || fontfiles (myfile).n
                 || ' 0 R';
            end if;

            p_out (s || '>>');
            p_out ('endobj');
         else
            -- Allow for additional types
            methode := 'p_put' || strtolower (mytype);

            if (not methode_exists (methode))
            then
               error ('Unsupported font type: ' || mytype);
            end if;
         end if;

         k := fonts.next (k);
      end loop;
   exception
      when others
      then
         error ('p_putfonts : ' || sqlerrm);
   end p_putfonts;

----------------------------------------------------------------------------------------
   procedure p_putimages
   is
      filter                        word;
      info                          recimage;
      v                             txt;
      trns                          txt;
      pal                           txt;
   begin
      if (b_compress)
      then
         filter := '/Filter /FlateDecode ';
      else
         filter := '';
      end if;

      v := images.first;

      while (v is not null)
      loop
         p_newobj ();
         images (v).n := n;
         info := images (v);
         p_out ('<</Type /XObject');
         p_out ('/Subtype /Image');
         p_out ('/Width ' || info.w);
         p_out ('/Height ' || info.h);

         if (info.cs = 'Indexed')
         then
            p_out (   '/ColorSpace [/Indexed /DeviceRGB '
                   || to_char (strlen (info.pal) / 3 - 1)
                   || ' '
                   || to_char (n + 1)
                   || ' 0 R]'
                  );
         else
            p_out ('/ColorSpace /' || info.cs);

            if (info.cs = 'DeviceCMYK')
            then
               p_out ('/Decode (1 0 1 0 1 0 1 0)');
            end if;
         end if;

         p_out ('/BitsPerComponent ' || info.bpc);

         if (info.f is not null)
         then
            p_out ('/Filter /' || info.f);
         end if;

         if (info.parms is not null)
         then
            p_out (info.parms);
         end if;

         if (info.trns.first is not null)
         then
            trns := '';

            for i in info.trns.first .. info.trns.count
            loop
               trns :=
                             trns || info.trns (i) || ' ' || info.trns (i)
                             || ' ';
            end loop;

            p_out ('/Mask (' || trns || ')');
         end if;

         p_out ('/Length ' || dbms_lob.getlength (info.data) || '>>');
         p_putstream (info.data);
         images (v).data := null;
         p_out ('endobj');

         --Palette
         if (info.cs = 'Indexed')
         then
            p_newobj ();

            if (b_compress)
            then
               -- gzcompress($info('pal'))
               null;
            else
               pal := info.pal;
            end if;

            p_out ('<<' || filter || '/Length ' || strlen (pal) || '>>');
            p_putstream (pal);
            p_out ('endobj');
         end if;

         v := images.next (v);
      end loop;
   exception
      when others
      then
         error ('p_putimages : ' || sqlerrm);
   end p_putimages;

----------------------------------------------------------------------------------------
   procedure p_putresources
   is
   begin
      p_putfonts ();
      p_putimages ();
      -- Resource dictionary
      offsets (2) := getpdfdoclength ();
      p_out ('2 0 obj');
      p_out ('<<');
      p_putresourcedict ();
      p_out ('>>');
      p_out ('endobj');
   exception
      when others
      then
         error ('p_putresources : ' || sqlerrm);
   end p_putresources;

----------------------------------------------------------------------------------------
   procedure p_putinfo
   is
   begin
      p_out ('/Producer ' || p_textstring ('PDFBLOB ' || pdfblob_version));

      if (not empty (title))
      then
         p_out ('/Title ' || p_textstring (title));
      end if;

      if (not empty (subject))
      then
         p_out ('/Subject ' || p_textstring (subject));
      end if;

      if (not empty (author))
      then
         p_out ('/Author ' || p_textstring (author));
      end if;

      if (not empty (keywords))
      then
         p_out ('/Keywords ' || p_textstring (keywords));
      end if;

      if (not empty (creator))
      then
         p_out ('/Creator ' || p_textstring (creator));
      end if;

      p_out ('/CreationDate ' || p_textstring ('D:' || date_ymdhis ()));
   exception
      when others
      then
         error ('p_putinfo : ' || sqlerrm);
   end p_putinfo;

----------------------------------------------------------------------------------------
   procedure p_putcatalog
   is
   begin
      p_out ('/Type /Catalog');
      p_out ('/Pages 1 0 R');

      if (zoommode = 'fullpage')
      then
         p_out ('/OpenAction [3 0 R /Fit]');
      elsif (zoommode = 'fullwidth')
      then
         p_out ('/OpenAction [3 0 R /FitH null]');
      elsif (zoommode = 'real')
      then
         p_out ('/OpenAction [3 0 R /XYZ null null 1]');
      elsif (not is_string (zoommode))
      then
         p_out ('/OpenAction [3 0 R /XYZ null null ' || (zoommode / 100) || ']');
      end if;

      if (layoutmode = 'single')
      then
         p_out ('/PageLayout /SinglePage');
      elsif (layoutmode = 'continuous')
      then
         p_out ('/PageLayout /OneColumn');
      elsif (layoutmode = 'two')
      then
         p_out ('/PageLayout /TwoColumnLeft');
      end if;
   exception
      when others
      then
         error ('p_putcatalog : ' || sqlerrm);
   end p_putcatalog;

----------------------------------------------------------------------------------------
   procedure p_putheader
   is
   begin
      p_out ('%PDF-' || pdfversion);
   end p_putheader;

----------------------------------------------------------------------------------------
   procedure p_puttrailer
   is
   begin
      p_out ('/Size ' || (n + 1));
      p_out ('/Root ' || n || ' 0 R');
      p_out ('/Info ' || (n - 1) || ' 0 R');
   end p_puttrailer;

----------------------------------------------------------------------------------------
   procedure p_endpage
   is
   begin
      -- End of page contents
      state := 1;
   end p_endpage;

----------------------------------------------------------------------------------------
   procedure p_putpages
   is
      nb                            number := page;
      filter                        varchar2 (200);
      annots                        bigtext;
      rect                          txt;
      kids                          txt;
      v_0                           varchar2 (255);
      v_1                           varchar2 (255);
      v_2                           varchar2 (255);
      v_3                           varchar2 (255);
      v_4                           varchar2 (255);
      v_0n                          number;
      v_1n                          number;
      v_2n                          number;
      v_3n                          number;
   begin
      -- Replace number of pages
      if not empty (aliasnbpages)
      then
         for i in 1 .. nb
         loop
            pages (i) :=
                                      str_replace (aliasnbpages, nb, pages (i));
         end loop;
      end if;

      if (deforientation = 'P')
      then
         wpt := fwpt;
         hpt := fhpt;
      else
         wpt := fhpt;
         hpt := fwpt;
      end if;

      if (b_compress)
      then
         filter := '/Filter /FlateDecode ';
      else
         filter := '';
      end if;

      for i in 1 .. nb
      loop
         -- Page
         p_newobj ();
         p_out ('<</Type /Page');
         p_out ('/Parent 1 0 R');

         if (orientationchanges.exists (i))
         then
            p_out ('/MediaBox [0 0 ' || tochar (hpt) || ' ' || tochar (wpt)
                   || ']'
                  );
         end if;

         p_out ('/Resources 2 0 R');

         if (pagelinks.exists (i))
         then
            --Links     [one/page]
            annots := '/Annots [';
            --for v in PageLinks(i).first..PageLinks(i).last loop
            v_0 := pagelinks (i).zero;
            v_0n := tonumber (v_0);
            v_1 := pagelinks (i).un;
            v_1n := tonumber (v_1);
            v_2 := pagelinks (i).deux;
            v_2n := tonumber (v_2);
            v_3 := pagelinks (i).trois;
            v_3n := tonumber (v_3);
            v_4 := pagelinks (i).quatre;
            rect :=
                  tochar (v_0)
               || ' '
               || tochar (v_1)
               || ' '
               || tochar (v_0n + v_2n)
               || ' '
               || tochar (v_1n - v_3n);
            annots :=
                  annots
               || '<</Type /Annot /Subtype /Link /Rect ['
               || rect
               || '] /Border [0 0 0] ';

            if is_string (pagelinks (i).quatre)
            then
               annots :=
                     annots
                  || '/A <</S /URI /URI '
                  || p_textstring (pagelinks (i).quatre)
                  || '>>>>';
            end if;

            --end loop;
            p_out (annots || ']');
         end if;

         p_out ('/Contents ' || to_char (n + 1) || ' 0 R>>');
         p_out ('endobj');
         -- Page content
         p_newobj ();
         p_out ('<<' || filter || '/Length ' || strlen (pages (i)) || '>>');
         p_putstream (pages (i));
         p_out ('endobj');
      end loop;

      -- Pages root
      offsets (1) := getpdfdoclength ();
      p_out ('1 0 obj');
      p_out ('<</Type /Pages');
      kids := '/Kids [';

      for i in 0 .. nb
      loop
         kids := kids || to_char (3 + 2 * i) || ' 0 R ';
      end loop;

      p_out (kids || ']');
      p_out ('/Count ' || nb);
      p_out ('/MediaBox [0 0 ' || tochar (wpt) || ' ' || tochar (hpt) || ']');
      p_out ('>>');
      p_out ('endobj');
   exception
      when others
      then
         error ('p_putpages : ' || sqlerrm);
   end p_putpages;

----------------------------------------------------------------------------------------
   procedure p_enddoc
   is
      o                             number;
   begin
      p_putheader ();
      p_putpages ();
      p_putresources ();
      -- Info
      p_newobj ();
      p_out ('<<');
      p_putinfo ();
      p_out ('>>');
      p_out ('endobj');
      -- Catalog
      p_newobj ();
      p_out ('<<');
      p_putcatalog ();
      p_out ('>>');
      p_out ('endobj');
      -- Cross-ref
      o := getpdfdoclength ();
      p_out ('xref');
      p_out ('0 ' || (n + 1));
      p_out ('0000000000 65535 f ');

      for i in 1 .. n
      loop
         p_out (   substr ('0000000000', 1, 10 - length (offsets (i)))
                || offsets (i)
                || ' 00000 n '
               );
      end loop;

      -- Trailer
      p_out ('trailer');
      p_out ('<<');
      p_puttrailer ();
      p_out ('>>');
      p_out ('startxref');
      p_out (o);
      p_out ('%%EOF');
      state := 3;
   exception
      when others
      then
         error ('p_enddoc : ' || sqlerrm);
   end p_enddoc;

----------------------------------------------------------------------------------------
   procedure p_beginpage (
      orientation                         varchar2
   )
   is
      myorientation                 word := orientation;
   begin
      page := page + 1;
      pages (page) := '';
      state := 2;
      x := lmargin;
      y := tmargin;
      fontfamily := '';

      -- Page orientation
      if (empty (myorientation))
      then
         myorientation := deforientation;
      else
         myorientation := substr (myorientation, 1, 1);
         myorientation := strtoupper (myorientation);

         if (myorientation != deforientation)
         then
            orientationchanges (page) := true;
         end if;
      end if;

      if (myorientation != curorientation)
      then
         -- Change orientation
         if (orientation = 'P')
         then
            wpt := fwpt;
            hpt := fhpt;
            w := fw;
            h := fh;
         else
            wpt := fhpt;
            hpt := fwpt;
            w := fh;
            h := fw;
         end if;

         pagebreaktrigger := h - bmargin;
         curorientation := myorientation;
      end if;
   exception
      when others
      then
         error ('p_beginpage : ' || sqlerrm);
   end p_beginpage;

----------------------------------------------------------------------------------------
   function p_dounderline (
      px                                  number
    , py                                  number
    , ptxt                                varchar2
   )
      return varchar2
   is
      up                            word := currentfont.up;
      ut                            word := currentfont.ut;
      w                             number := 0;
   begin
      w :=
                           getstringwidth (ptxt)
                           + ws * substr_count (ptxt, ' ');
      return    tochar (px * k, 2)
             || ' '
             || tochar ((h - (py - up / 1000 * fontsize)) * k, 2)
             || ' '
             || tochar (w * k, 2)
             || ' '
             || tochar (-ut / 1000 * fontsizept, 2)
             || ' re f';
   exception
      when others
      then
         error ('p_dounderline : ' || sqlerrm);
   end p_dounderline;

--------------------------------------------------------------------------------
-- Function to convert a binary unsigned integer
-- into a PLSQL number
--------------------------------------------------------------------------------
   function p_freadint (
      p_data                     in       varchar2
   )
      return number
   is
      l_number                      number default 0;
      l_bytes                       number default length (p_data);
      big_endian           constant boolean default true;
   begin
      if (big_endian)
      then
         for i in 1 .. l_bytes
         loop
            l_number :=
               l_number + ascii (substr (p_data, i, 1))
                          * power (2, 8 * (i - 1));
         end loop;
      else
         for i in 1 .. l_bytes
         loop
            l_number :=
                 l_number
               +   ascii (substr (p_data, l_bytes - i + 1, 1))
                 * power (2, 8 * (i - 1));
         end loop;
      end if;

      return l_number;
   end p_freadint;

/*
--------------------------------------------------------------------------------
-- Parse an image
--------------------------------------------------------------------------------
function p_parseImage(pFile varchar2) return recImage is
  myImg ordsys.ordImage := ordsys.ordImage.init();
  myImgInfo recImage;
  myCtFormat word;
  -- colspace word;
  myblob blob;
  png_signature constant varchar2(8) := chr(137) || 'PNG' || chr(13) || chr(10) || chr(26) || chr(10);
  amount number;
  f number default 1;
  buf varchar2(8192);
  bufRaw raw(32000);
  amount_rd number;
  amount_wr number;
  offset_rd number;
  offset_wr number;
  ct word;
  colors pls_integer;
  n number;
  myType word;
  -- NullTabN tn;
  imgDataStartsHere number;
  imgDataStopsHere number;
  nb_chuncks number;
  ---------------------------------------------------------------------------------------------
  function freadb(pBlob in out nocopy blob, pHandle in out number, pLength in out number) return raw is
   l_data_raw  raw(8192);
    l_hdr_size  number default 2000;
  begin
   dbms_lob.read(pBlob, pLength, pHandle, l_data_raw);
   pHandle := pHandle + pLength;
   return l_data_raw;
  end freadb;

  function fread(pBlob in out nocopy blob, pHandle in out number, pLength in out number) return varchar2 is
  begin
   return utl_raw.cast_to_varchar2(freadb(pBlob, pHandle, pLength));
  end fread;

  ---------------------------------------------------------------------------------------------

begin
    myImgInfo.data := empty_blob();
   myImg := getImageFromUrl(pFile);
   myCtFormat := myImg.getContentFormat();
   myblob := myImg.getContent();
   myImgInfo.i := 1;
   -- reading the blob
   amount := 8;
   --Check signature
   if(fread(myblob, f, amount) != png_signature ) then
       Error('Not a PNG file: ' || pFile);
   end if;

   -- Read header chunk
   amount := 4;
   buf := fread(myblob, f, amount);

   buf := fread(myblob, f, amount);
   if(buf != 'IHDR') then
      Error('Incorrect PNG file: ' || pFile);
   end if;

    myImgInfo.w := myImg.getWidth();
    myImgInfo.h := myImg.getHeight();

   -- ^^^ I have already get width and height, so go forward (read 4 Bytes twice)
   buf := fread(myblob, f, amount);
   buf := fread(myblob, f, amount);

   amount := 1;

   myImgInfo.bpc := ord(fread(myblob, f, amount));
   if( myImgInfo.bpc > 8) then
      Error('16-bit depth not supported: ' || pFile);
   end if;

   ct := ord(fread(myblob, f, amount));
   if( ct = 0 ) then
      myImgInfo.cs := 'DeviceGray';
   elsif( ct = 2 ) then
      myImgInfo.cs := 'DeviceRGB';
   elsif( ct = 3 ) then
      myImgInfo.cs := 'Indexed';
   else
      Error('Alpha channel not supported: ' || pFile);
    end if;
   if( ord(fread(myblob, f, amount)) != 0 ) then
      Error('Unknown compression method: ' || pFile);
   end if;
   if( ord(fread(myblob, f, amount)) != 0 ) then
      Error('Unknown filter method: ' || pFile);
   end if;
   if( ord(fread(myblob, f, amount)) != 0 ) then
      Error('Interlacing not supported: ' || pFile);
   end if;

   amount := 4;
   buf := fread(myblob, f, amount);

   if (ct = 2 ) then
     colors := 3;
   else
     colors := 1;
   end if;

   myImgInfo.parms := '/DecodeParms <</Predictor 15 /Colors ' || to_char(colors) || ' /BitsPerComponent ' || myImgInfo.bpc || ' /Columns ' || myImgInfo.w || '>>';
   -- scan chunks looking for palette, transparency and image data
   loop
       amount := 4;
      n := utl_raw.cast_to_binary_integer(freadb(myblob, f, amount));
      myType := fread(myblob, f, amount);
      if(myType = 'PLTE') then
         -- Read palette
         amount := n;
         myImgInfo.pal := fread(myblob, f, amount);
         amount := 4;
         buf := fread(myblob, f, amount);
      elsif(myType = 'tRNS') then
         --   Read transparency info
         amount := n;
         buf := fread(myblob, f, amount);
         if(ct = 0) then
             myImgInfo.trns(1) := ord(substr(buf,1,1));
         elsif( ct = 2) then
            myImgInfo.trns(1) := ord(substr(buf,1,1));
            myImgInfo.trns(2) := ord(substr(buf,3,1));
            myImgInfo.trns(3) := ord(substr(buf,5,1));
         else
            if(instr(buf,chr(0)) > 0) then
               myImgInfo.trns(1) := instr(buf,chr(0));
            end if;
         end if;
         amount := 4;
         buf := fread(myblob, f, amount);
      elsif(myType = 'IDAT') then
         -- Read image data block after the loop, just mark the begin of data
         imgDataStartsHere := f;
         exit;
      elsif(myType = 'IEND') then

         exit;
      else
         amount := n + 4;
         buf := fread(myblob, f, amount);
      end if;
      exit when n is null or n = 0;
   end loop;

   imgDataStopsHere := dbms_lob.instr(myblob, utl_raw.cast_to_raw('IEND'),1,1);
   -- copy image in the structure.
   amount_rd := 8192;
   amount_wr := 8192;
   offset_rd := 1;
   offset_wr := 1;
   nb_chuncks := ceil(((imgDataStopsHere - imgDataStartsHere)) / amount_rd);
   dbms_lob.createtemporary(myImgInfo.data, true);
   for i in 1..nb_chuncks loop
      offset_rd := imgDataStartsHere + ((i - 1) * amount_rd);

      dbms_lob.read(myblob, amount_rd, offset_rd, bufRaw);
      offset_wr := ((i - 1) * amount_wr) + 1;
      amount_wr := amount_rd;
      dbms_lob.write(myImgInfo.data, amount_wr, offset_wr, bufRaw);
   end loop;
   if( myImgInfo.cs = 'Indexed' and myImgInfo.pal is null) then
      Error('Missing palette in '|| pFile);
   end if;
    myImgInfo.f := 'FlateDecode';
    return myImgInfo;
exception
  when others then
    Error('p_parseImage : '||SQLERRM);
   return myImgInfo;
end p_parseImage;

*/

   --------------------------------------------------------------------------------
-- Parse an image
--------------------------------------------------------------------------------
   function p_parseimage (
      pfile                               varchar2
   )
      return recimage
   is
      myimg                         ordsys.ordimage := ordsys.ordimage.init ();
      myimginfo                     recimage;
      myctformat                    word;
      colspace                      word;
      myblob                        blob;
      chunk_content                 blob;
      png_signature        constant varchar2 (8)
 := chr (137) || 'PNG' || chr (13) || chr (10) || chr (26)
                 || chr (10);
      signature_len                 integer := 8;
      chunklength_len               integer := 4;
      chunktype_len                 integer := 4;
      chunkdata_len                 integer;
      widthheight_len               integer := 8;
      hdrflag_len                   integer := 1;
      crc_len                       integer := 4;
      chunk_num                     integer := 0;
      --amount number;
      f                             number default 1;
      f_chunk                       number default 1;
      buf                           varchar2 (8192);
      ct                            word;
      colors                        pls_integer;
      n                             number;
      mytype                        word;
      nulltabn                      tn;
      imgdatastartshere             number;
      imgdatastopshere              number;
      nb_chuncks                    number;

---------------------------------------------------------------------------------------------
      function freadb (
         pblob                      in out nocopy blob
       , phandle                    in out   number
       , plength                    in out   number
      )
         return raw
      is
         l_data_raw                    raw (8192);
         l_hdr_size                    number default 2000;
      begin
         dbms_lob.read (pblob, plength, phandle, l_data_raw);
         phandle := phandle + plength;
         return l_data_raw;
      end freadb;

      function fread (
         pblob                      in out nocopy blob
       , phandle                    in out   number
       , plength                    in out   number
      )
         return varchar2
      is
      begin
         return utl_raw.cast_to_varchar2 (freadb (pblob, phandle, plength));
      end fread;

      procedure fread_blob (
         pblob                      in out nocopy blob
       , phandle                    in out   number
       , plength                    in out   number
       , pdestblob                  in out nocopy blob
      )
      is
      begin
         dbms_lob.trim (pdestblob, 0);
         dbms_lob.copy (pdestblob, pblob, plength, 1, phandle);
         phandle := phandle + plength;
      end fread_blob;
---------------------------------------------------------------------------------------------
   begin
      dbms_lob.createtemporary (chunk_content, true);
      dbms_lob.open (chunk_content, dbms_lob.lob_readwrite);
      --we use the package level imgBlob variable so the temp blob will persist throughout pdf creation.
      dbms_lob.createtemporary (imgblob, true);
      myimginfo.data := imgblob;
      dbms_lob.open (myimginfo.data, dbms_lob.lob_readwrite);
      myimg := getimagefromurl (pfile);
      myctformat := myimg.getcontentformat ();
      myblob := myimg.getcontent ();
      myimginfo.i := 1;

      -- reading the blob
      -- Check signature
      if (fread (myblob, f, signature_len) != png_signature)
      then
         error ('Not a PNG file: ' || pfile);
      end if;

      myimginfo.w := myimg.getwidth ();
      myimginfo.h := myimg.getheight ();

      -- scan chunks looking for palette, transparency and image data
      loop
         chunkdata_len :=
            utl_raw.cast_to_binary_integer (freadb (myblob, f, chunklength_len));
         mytype := fread (myblob, f, chunktype_len);

         --read chunk contents into separate blob
         if (chunkdata_len > 0)
         then
            fread_blob (myblob, f, chunkdata_len, chunk_content);
            f_chunk := 1;
         end if;

         chunk_num := chunk_num + 1;
         --discard the crc
         buf := fread (myblob, f, crc_len);

         if (chunk_num = 1 and mytype != 'IHDR')
         then
            error ('Incorrect PNG file: ' || pfile);
         elsif (mytype = 'IHDR')
         then
            -- ^^^ I have already get width and height, so go forward (read 4 Bytes twice)
            buf :=
                                fread (chunk_content, f_chunk, widthheight_len);
            myimginfo.bpc :=
                              ord (fread (chunk_content, f_chunk, hdrflag_len));

            if (myimginfo.bpc > 8)
            then
               error ('16-bit depth not supported: ' || pfile);
            end if;

            ct:=
                               ord (fread (chunk_content, f_chunk, hdrflag_len));

            if (ct = 0)
            then
               myimginfo.cs := 'DeviceGray';
            elsif (ct = 2)
            then
               myimginfo.cs := 'DeviceRGB';
            elsif (ct = 3)
            then
               myimginfo.cs := 'Indexed';
            else
               error ('Alpha channel not supported: ' || pfile);
            end if;

            if (ord (fread (chunk_content, f_chunk, hdrflag_len)) != 0)
            then
               error ('Unknown compression method: ' || pfile);
            end if;

            if (ord (fread (chunk_content, f_chunk, hdrflag_len)) != 0)
            then
               error ('Unknown filter method: ' || pfile);
            end if;

            if (ord (fread (chunk_content, f_chunk, hdrflag_len)) != 0)
            then
               error ('Interlacing not supported: ' || pfile);
            end if;

            if (ct = 2)
            then
               colors := 3;
            else
               colors := 1;
            end if;

            myimginfo.parms :=
                  '/DecodeParms <</Predictor 15 /Colors '
               || to_char (colors)
               || ' /BitsPerComponent '
               || myimginfo.bpc
               || ' /Columns '
               || myimginfo.w
               || '>>';
         elsif (mytype = 'PLTE')
         then
            -- Read palette
            myimginfo.pal :=
                                  fread (chunk_content, f_chunk, chunkdata_len);
         elsif (mytype = 'tRNS')
         then
            --   Read transparency info
            buf :=
                                  fread (chunk_content, f_chunk, chunkdata_len);

            if (ct = 0)
            then
               myimginfo.trns (1) := ord (substr (buf, 1, 1));
            elsif (ct = 2)
            then
               myimginfo.trns (1) := ord (substr (buf, 1, 1));
               myimginfo.trns (2) := ord (substr (buf, 3, 1));
               myimginfo.trns (3) := ord (substr (buf, 5, 1));
            else
               if (instr (buf, chr (0)) > 0)
               then
                  myimginfo.trns (1) := instr (buf, chr (0));
               end if;
            end if;
         elsif (mytype = 'IDAT')
         then
            -- Read image data block after the loop, just mark the begin of data
            dbms_lob.append (myimginfo.data, chunk_content);
         elsif (mytype = 'IEND')
         then
            exit;
         end if;
      end loop;

      if (myimginfo.cs = 'Indexed' and myimginfo.pal is null)
      then
         error ('Missing palette in ' || pfile);
      end if;

      myimginfo.f := 'FlateDecode';
      dbms_lob.close (chunk_content);
      dbms_lob.close (myimginfo.data);
      dbms_lob.freetemporary (chunk_content);
      return myimginfo;
   exception
      when others
      then
         error ('p_parseImage : ' || sqlerrm);
         return myimginfo;
   end p_parseimage;

/*******************************************************************************
*                                                                              *
*                               Public methods                                 *
*                                                                              *
********************************************************************************/

----------------------------------------------------------------------------------------
-- Methods added to PDF primary class
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- SetDash Ecrire en pointillés
----------------------------------------------------------------------------------------
   procedure setdash (
      pblack                              number default 0
    , pwhite                              number default 0
   )
   is
      s                             txt;
   begin
      if (pblack != 0 or pwhite != 0)
      then
         s :=
               '['
            || tochar (pblack * k, 3)
            || ' '
            || tochar (pwhite * k, 3)
            || '] 0 d';
      else
         s := '[] 0 d';
      end if;

      p_out (s);
   end setdash;

----------------------------------------------------------------------------------------
-- Methods from PDF primary class
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
   procedure error (
      pmsg  varchar2
   )
   is
   begin
      if gb_mode_debug
      then
         print ('<pre>');

         for i in pdfdoc.first .. pdfdoc.last
         loop
            if i is not null
            then
               print (replace (replace (pdfdoc (i), '>', '&gt;'), '<', '&lt;'));
            end if;
         end loop;

         print ('</pre>');
      end if;

      -- Fatal error
      raise_application_error (-20100, '<B>PDFBLOB error: </B>' || pmsg);
   end error;

----------------------------------------------------------------------------------------
   function getcurrentfontsize
      return number
   is
   begin
      -- Get fontsizePt
      return fontsizept;
   end getcurrentfontsize;

----------------------------------------------------------------------------------------
   function getcurrentfontstyle
      return varchar2
   is
   begin
      -- Get fontStyle
      return fontstyle;
   end getcurrentfontstyle;

----------------------------------------------------------------------------------------
   function getcurrentfontfamily
      return varchar2
   is
   begin
      -- Get fontStyle
      return fontfamily;
   end getcurrentfontfamily;

----------------------------------------------------------------------------------------
   procedure ln (
      h number default null
   )
   is
   begin
      -- Line feed; default value is last cell height
      x := lmargin;

      if (is_string (h))
      then
         y := y + lasth;
      else
         y := y + h;
      end if;
   end ln;

----------------------------------------------------------------------------------------
   function getx
      return number
   is
   begin
      -- Get x position
      return x;
   end getx;

----------------------------------------------------------------------------------------
   procedure setx (
      px  number
   )
   is
   begin
      -- Set x position
      if (px >= 0)
      then
         x := px;
      else
         x := w + px;
      end if;
   end setx;

----------------------------------------------------------------------------------------
   function gety
      return number
   is
   begin
      -- Get y position
      return y;
   end gety;

----------------------------------------------------------------------------------------
   procedure sety (
      py number
   )
   is
   begin
      -- Set y position and reset x
      x := lmargin;

      if (py >= 0)
      then
         y := py;
      else
         y := h + py;
      end if;
   end sety;

----------------------------------------------------------------------------------------
   procedure setxy (
      x number
    , y number
   )
   is
   begin
      -- Set x and y positions
      sety (y);
      setx (x);
   end setxy;

----------------------------------------------------------------------------------------
   procedure setheaderproc (
      headerprocname             in       varchar2
   )
   is
   begin
      myheader_proc := headerprocname;
   end;

   procedure setfooterproc (
      footerprocname             in       varchar2
   )
   is
   begin
      myfooter_proc := footerprocname;
   end;

----------------------------------------------------------------------------------------
   procedure setmargins (
      left  number
    , top   number
    , right number default -1
   )
   is
      myright                       margin := right;
   begin
      -- Set left, top and right margins
      lmargin := left;
      tmargin := top;

      if (myright = -1)
      then
         myright := left;
      end if;

      rmargin := myright;
   end setmargins;

----------------------------------------------------------------------------------------
   procedure setleftmargin (
      pmargin number
   )
   is
   begin
      -- Set left margin
      lmargin := pmargin;

      if (page > 0 and x < pmargin)
      then
         x := pmargin;
      end if;
   end setleftmargin;

----------------------------------------------------------------------------------------
   procedure settopmargin (
      pmargin number
   )
   is
   begin
      -- Set top margin
      tmargin := pmargin;
   end settopmargin;

----------------------------------------------------------------------------------------
   procedure setrightmargin (
      pmargin number
   )
   is
   begin
      -- Set right margin
      rmargin := pmargin;
   end setrightmargin;

----------------------------------------------------------------------------------------
   procedure setautopagebreak (
      pauto   boolean
    , pmargin number default 0
   )
   is
   begin
      -- Set auto page break mode and triggering margin
      autopagebreak := pauto;
      bmargin := pmargin;
      pagebreaktrigger := h - pmargin;
   end setautopagebreak;

----------------------------------------------------------------------------------------
   procedure setdisplaymode (
      zoom   varchar2
    , layout varchar2 default 'continuous'
   )
   is
   begin
      -- Set display mode in viewer
      if (   zoom in ('fullpage', 'fullwidth', 'real', 'default')
          or not is_string (zoom)
         )
      then
         zoommode := zoom;
      else
         error ('Incorrect zoom display mode: ' || zoom);
      end if;

      if (layout in ('single', 'continuous', 'two', 'default'))
      then
         layoutmode := layout;
      else
         error ('Incorrect layout display mode: ' || layout);
      end if;
   end setdisplaymode;

----------------------------------------------------------------------------------------
   procedure setcompression (
      p_compress                          boolean default false
   )
   is
   begin
      -- Set page compression
      if (function_exists ('gzcompress'))
      then
         b_compress := p_compress;
      else
         b_compress := false;
      end if;
   end setcompression;

----------------------------------------------------------------------------------------
   procedure settitle (
      ptitle varchar2
   )
   is
   begin
      -- Title of document
      title := ptitle;
   end settitle;

----------------------------------------------------------------------------------------
   procedure setsubject (
      psubject                            varchar2
   )
   is
   begin
      -- Subject of document
      subject := psubject;
   end setsubject;

----------------------------------------------------------------------------------------
   procedure setauthor (
      pauthor varchar2
   )
   is
   begin
      -- Author of document
      author := pauthor;
   end setauthor;

----------------------------------------------------------------------------------------
   procedure setkeywords (
      pkeywords                           varchar2
   )
   is
   begin
      -- Keywords of document
      keywords := pkeywords;
   end setkeywords;

----------------------------------------------------------------------------------------
   procedure setcreator (
      pcreator                            varchar2
   )
   is
   begin
      -- Creator of document
      creator := pcreator;
   end setcreator;

----------------------------------------------------------------------------------------
   procedure setaliasnbpages (
      palias varchar2 default '{nb}'
   )
   is
   begin
      -- Define an alias for total number of pages
      aliasnbpages := palias;
   end setaliasnbpages;

----------------------------------------------------------------------------------------
   procedure header
   is
   begin
      -- MyHeader_Proc defined in Declaration
      if (not empty (myheader_proc))
      then
         execute immediate    'Begin '
                           || myheader_proc
                           || '; exception when others then raise; end;';
      end if;
   exception
      when others
      then
         error ('Header : ' || sqlerrm);
   end header;

----------------------------------------------------------------------------------------
   procedure footer
   is
   begin
      -- MyFooter_Proc defined in Declaration
      if (not empty (myfooter_proc))
      then
         execute immediate    'Begin '
                           || myfooter_proc
                           || '; exception when others then raise; end;';
      end if;
   exception
      when others
      then
         error ('Footer : ' || sqlerrm);
   end footer;

----------------------------------------------------------------------------------------
   function pageno
      return number
   is
   begin
      -- Get current page number
      return page;
   end pageno;

----------------------------------------------------------------------------------------
   procedure setdrawcolor (
      r number
    , g number default -1
    , b number default -1
   )
   is
   begin
      -- Set color for all stroking operations
      if ((r = 0 and g = 0 and b = 0) or g = -1)
      then
         drawcolor := tochar (r / 255, 3) || ' G';
      else
         drawcolor :=
               tochar (r / 255, 3)
            || ' '
            || tochar (g / 255, 3)
            || ' '
            || tochar (b / 255, 3)
            || ' RG';
      end if;

      if (page > 0)
      then
         p_out (drawcolor);
      end if;
   end setdrawcolor;

----------------------------------------------------------------------------------------
   procedure setfillcolor (
      r number
    , g number default -1
    , b number default -1
   )
   is
   begin
      -- Set color for all filling operations
      if ((r = 0 and g = 0 and b = 0) or g = -1)
      then
         fillcolor := tochar (r / 255, 3) || ' g';
      else
         fillcolor :=
               tochar (r / 255, 3)
            || ' '
            || tochar (g / 255, 3)
            || ' '
            || tochar (b / 255, 3)
            || ' rg';
      end if;

      if (fillcolor != textcolor)
      then
         colorflag := true;
      else
         colorflag := false;
      end if;

      if (page > 0)
      then
         p_out (fillcolor);
      end if;
   end setfillcolor;

----------------------------------------------------------------------------------------
   procedure settextcolor (
      r number
    , g number default -1
    , b number default -1
   )
   is
   begin
      -- Set color for text
      if ((r = 0 and g = 0 and b = 0) or g = -1)
      then
         textcolor := tochar (r / 255, 3) || ' g';
      else
         textcolor :=
               tochar (r / 255, 3)
            || ' '
            || tochar (g / 255, 3)
            || ' '
            || tochar (b / 255, 3)
            || ' rg';
      end if;

      if (fillcolor != textcolor)
      then
         colorflag := true;
      else
         colorflag := false;
      end if;
   end settextcolor;

----------------------------------------------------------------------------------------
   procedure setlinewidth (
      width number
   )
   is
   begin
      -- Set line width
      linewidth := width;

      if (page > 0)
      then
         p_out (tochar (width * k, 2) || ' w');
      end if;
   end setlinewidth;

----------------------------------------------------------------------------------------
   procedure line (
      x1 number
    , y1 number
    , x2 number
    , y2 number
   )
   is
   begin
      -- Draw a line
      p_out (   tochar (x1 * k, 2)
             || ' '
             || tochar ((h - y1) * k, 2)
             || ' m '
             || tochar (x2 * k, 2)
             || ' '
             || tochar ((h - y2) * k, 2)
             || ' l S'
            );
   end line;

----------------------------------------------------------------------------------------
   procedure rect (
      px     number
    , py     number
    , pw     number
    , ph     number
    , pstyle varchar2 default ''
   )
   is
      op                            word;
   begin
      -- Draw a rectangle
      if (pstyle = 'F')
      then
         op:= 'f';
      elsif (pstyle = 'FD' or pstyle = 'DF')
      then
         op:= 'B';
      else
         op:= 'S';
      end if;

      p_out (   tochar (px * k, 2)
             || ' '
             || tochar ((h - py) * k, 2)
             || ' '
             || tochar (pw * k, 2)
             || ' '
             || tochar (-ph * k, 2)
             || ' re '
             || op
            );
   end rect;

----------------------------------------------------------------------------------------
   function addlink
      return number
   is
      nb_link                       number := links.count + 1;
   begin
      -- Create a new internal link
      links (nb_link).zero := 0;
      links (nb_link).un := 0;
      return nb_link;
   end addlink;

----------------------------------------------------------------------------------------
   procedure setlink (
      plink  number
    , py     number default 0
    , ppage  number default -1
   )
   is
      mypy                          number := py;
      myppage                       number := ppage;
   begin
      -- Set destination of internal link
      if (mypy = -1)
      then
         mypy := y;
      end if;

      if (myppage = -1)
      then
         myppage := page;
      end if;

      links (plink).zero := myppage;
      links (plink).un := mypy;
   end setlink;

----------------------------------------------------------------------------------------
   procedure link (
      px     number
    , py     number
    , pw     number
    , ph     number
    , plink  varchar2
   )
   is
      v_last_plink                  integer;
      v_ntoextend                   integer;
      v_rec                         rec5;
   begin
       -- Put a link on the page
      -- Init PageLinks, if not exists
      begin
         v_last_plink := pagelinks.count;
      exception
         when others
         then
            pagelinks := linksarray (v_rec);
      end;

      -- extend, so PageLinks(page) exists
      v_last_plink := pagelinks.last;
      v_ntoextend := page - v_last_plink;

      if v_ntoextend > 0
      then
         pagelinks.extend (v_ntoextend);
      end if;

      -- set values
      pagelinks (page).zero := px * k;
      pagelinks (page).un := hpt - py * k;
      pagelinks (page).deux := pw * k;
      pagelinks (page).trois := ph * k;
      pagelinks (page).quatre := plink;
   end link;

----------------------------------------------------------------------------------------
   procedure text (
      px     number
    , py     number
    , ptxt   varchar2
   )
   is
      s varchar2 (2000);
   begin
      -- Output a string
      s :=
            'BT '
         || tochar (px * k, 2)
         || ' '
         || tochar ((h - py) * k, 2)
         || ' Td ('
         || p_escape (ptxt)
         || ') Tj ET';

      if (underline and ptxt is not null)
      then
         s := s || ' ' || p_dounderline (px, py, ptxt);
      end if;

      if (colorflag)
      then
         s := 'q ' || textcolor || ' ' || s || ' Q';
      end if;

      p_out (s);
   end text;

----------------------------------------------------------------------------------------
   function acceptpagebreak
      return boolean
   is
   begin
      -- Accept automatic page break or not
      return autopagebreak;
   end acceptpagebreak;

----------------------------------------------------------------------------------------
   procedure openpdf
   is
   begin
      -- Begin document
      state := 1;
   end openpdf;

----------------------------------------------------------------------------------------
   procedure closepdf
   is
   begin
      -- Terminate document
      if (state = 3)
      then
         return;
      end if;

      if (page = 0)
      then
         addpage ();
      end if;

      -- Page footer
      infooter := true;
      footer ();
      infooter := false;
      -- Close page
      p_endpage ();
      -- Close document
      p_enddoc ();
   end closepdf;

----------------------------------------------------------------------------------------
   procedure addpage (
      orientation                         varchar2 default ''
   )
   is
      myfamily                      txt;
      mystyle                       txt;
      mysize                        number := fontsizept;
      lw                            phrase := linewidth;
      dc                            phrase := drawcolor;
      fc                            phrase := fillcolor;
      tc                            phrase := textcolor;
      cf                            flag := colorflag;
   begin
      -- Start a new page
      if (state = 0)
      then
         openpdf ();
      end if;

      myfamily := fontfamily;

      if (underline)
      then
         mystyle := fontstyle || 'U';
      end if;

      if (page > 0)
      then
         -- Page footer
         infooter := true;
         footer ();
         infooter := false;
         -- Close page
         p_endpage ();
      end if;

      -- Start new page
      p_beginpage (orientation);
      -- Set line cap style to square
      p_out ('2 J');
      -- Set line width
      linewidth := lw;
      p_out (tochar (lw * k) || ' w');

      -- Set font
      if (myfamily is not null)
      then
         setfont (myfamily, mystyle, mysize);
      end if;

      -- Set colors
      drawcolor := dc;

      if (dc != '0 G')
      then
         p_out (dc);
      end if;

      fillcolor := fc;

      if (fc != '0 g')
      then
         p_out (fc);
      end if;

      textcolor := tc;
      colorflag := cf;
      -- Page header
      header ();

      -- Restore line width
      if (linewidth != lw)
      then
         linewidth := lw;
         p_out (tochar (lw * k) || ' w');
      end if;

      -- Restore font
      if myfamily is null
      then
         setfont (myfamily, mystyle, mysize);
      end if;

      -- Restore colors
      if (drawcolor != dc)
      then
         drawcolor := dc;
         p_out (dc);
      end if;

      if (fillcolor != fc)
      then
         fillcolor := fc;
         p_out (fc);
      end if;

      textcolor := tc;
      colorflag := cf;
   end addpage;

----------------------------------------------------------------------------------------
   procedure pdfblob (
      orientation  varchar2 default 'P'
    , unit         varchar2 default 'mm'
    , format       varchar2 default 'A4'
   )
   is
      myorientation                 word := orientation;
      myformat                      word := format;
      mymargin                      margin;
   begin
      -- Some checks
      p_dochecks ();
      -- Initialization of properties
      page := 0;
      n := 2;
      -- Open the final structure for the PDF document.
      pdfdoc (1) := null;
      state := 0;
      infooter := false;
      lasth := 0;
      --FontFamily:='';
      fontfamily := 'helvetica';
      fontstyle := '';
      fontsizept := 12;
      underline := false;
      drawcolor := '0 G';
      fillcolor := '0 g';
      textcolor := '0 g';
      colorflag := false;
      ws := 0;
      -- Standard fonts
      corefonts ('courier') := 'Courier';
      corefonts ('courierB') := 'Courier-Bold';
      corefonts ('courierI') := 'Courier-Oblique';
      corefonts ('courierBI') := 'Courier-BoldOblique';
      corefonts ('helvetica') := 'Helvetica';
      corefonts ('helveticaB') := 'Helvetica-Bold';
      corefonts ('helveticaI') := 'Helvetica-Oblique';
      corefonts ('helveticaBI') := 'Helvetica-BoldOblique';
      corefonts ('times') := 'Times-Roman';
      corefonts ('timesB') := 'Times-Bold';
      corefonts ('timesI') := 'Times-Italic';
      corefonts ('timesBI') := 'Times-BoldItalic';
      corefonts ('symbol') := 'Symbol';
      corefonts ('zapfdingbats') := 'ZapfDingbats';

      -- Scale factor
      if (unit = 'pt')
      then
         k := 1;
      elsif (unit = 'mm')
      then
         k := 72 / 25.4;
      elsif (unit = 'cm')
      then
         k := 72 / 2.54;
      elsif (unit = 'in')
      then
         k := 72;
      else
         error ('Incorrect unit: ' || unit);
      end if;

      -- Others added properties
      linespacing := fontsizept / k;
                                            -- minimum line spacing in multicell

      -- Page format
      if (is_string (myformat))
      then
         myformat := strtolower (myformat);

         if (myformat = 'a3')
         then
            formatarray.largeur := 841.89;
            formatarray.hauteur := 1190.55;
         elsif (myformat = 'a4')
         then
            formatarray.largeur := 595.28;
            formatarray.hauteur := 841.89;
         elsif (myformat = 'a5')
         then
            formatarray.largeur := 420.94;
            formatarray.hauteur := 595.28;
         elsif (myformat = 'letter')
         then
            formatarray.largeur := 612;
            formatarray.hauteur := 792;
         elsif (myformat = 'legal')
         then
            formatarray.largeur := 612;
            formatarray.hauteur := 1008;
         else
            error ('Unknown page format: ' || myformat);
         end if;

         fwpt := formatarray.largeur;
         fhpt := formatarray.hauteur;
      else
         fwpt := formatarray.largeur * k;
         fhpt := formatarray.hauteur * k;
      end if;

      fw:= fwpt / k;
      fh:= fhpt / k;
      -- Page orientation
      myorientation := strtolower (myorientation);

      if (myorientation = 'p' or myorientation = 'portrait')
      then
         deforientation := 'P';
         wpt := fwpt;
         hpt := fhpt;
      elsif (myorientation = 'l' or myorientation = 'landscape')
      then
         deforientation := 'L';
         wpt := fhpt;
         hpt := fwpt;
      else
         error ('Incorrect orientation: ' || myorientation);
      end if;

      curorientation := deforientation;
      w := wpt / k;
      h := hpt / k;
      -- Page margins (1 cm)
      mymargin := 28.35 / k;
      setmargins (mymargin, mymargin);
      -- Interior cell margin (1 mm)
      cmargin := mymargin / 10;
      -- Line width (0.2 mm)
      linewidth := .567 / k;
      -- Automatic page break
      setautopagebreak (true, 2 * mymargin);
      -- Full width display mode
      setdisplaymode ('fullwidth');
      -- Disable compression
      setcompression (false);
      -- Set default PDF version number
      pdfversion := '1.4';
   end pdfblob;

----------------------------------------------------------------------------------------
   procedure addfont (
      family                              varchar2
    , style                               varchar2 default ''
    , filename                            varchar2 default ''
   )
   is
      myfamily                      word := family;
      mystyle                       word := style;
      myfile                        word := filename;
      fontkey                       word;
      fontcount                     number;
      i                             pls_integer;
      d                             pls_integer;
      nb                            pls_integer;
      mydiff                        varchar2 (2000);
      mytype                        varchar2 (256);
   begin
      -- Add a TrueType or Type1 font
      myfamily := strtolower (myfamily);

      if myfile is null
      then
         myfile := str_replace (' ', '', myfamily) || strtolower (mystyle) || '.php';
      end if;

      if (myfamily = 'arial')
      then
         myfamily := 'helvetica';
      end if;

      mystyle := strtoupper (mystyle);

      if (mystyle = 'IB')
      then
         mystyle := 'BI';
      end if;

      fontkey := myfamily || mystyle;

      if (fonts.exists (fontkey))
      then
         error ('Font already added: ' || myfamily || ' ' || mystyle);
      end if;

      p_includefont (fontkey);
      fontcount := nvl (fonts.count, 0) + 1;
      fonts (fontkey).i := fontcount;
      fonts (fontkey).type := 'core';
      fonts (fontkey).name := corefonts (fontkey);
      fonts (fontkey).up := -100;
      fonts (fontkey).ut := 50;
      fonts (fontkey).cw := pdf_charwidths (fontkey);
      fonts (fontkey).file := myfile;

      if (mydiff is not null)
      then
         -- Search existing encodings
         d := 0;
         nb:= diffs.count;

         for i in 1 .. nb
         loop
            if (diffs (i) = mydiff)
            then
               d := i;
               exit;
            end if;
         end loop;

         if (d = 0)
         then
            d := nb + 1;
            diffs (d) := mydiff;
         end if;

         fonts (fontkey).diff := d;
      end if;

      if (myfile is not null)
      then
         if (mytype = 'TrueType')
         then
            fontfiles (myfile).length1 := originalsize;
         else
            fontfiles (myfile).length1 := size1;
            fontfiles (myfile).length2 := size2;
         end if;
      end if;
   end addfont;

----------------------------------------------------------------------------------------
   procedure setfont (
      pfamily                             varchar2
    , pstyle                              varchar2 default ''
    , psize                               number default 0
   )
   is
      myfamily                      word := pfamily;
      mystyle                       word := pstyle;
      mysize                        number := psize;
      fontcount                     number := 0;
      myfontfile                    word;
      fontkey                       word;
   begin
      -- Select a font; size given in points
      myfamily := strtolower (myfamily);

      if myfamily is null
      then
         myfamily := fontfamily;
      end if;

      if (myfamily = 'arial')
      then
         myfamily := 'helvetica';
      elsif (myfamily = 'symbol' or myfamily = 'zapfdingbats')
      then
         mystyle := '';
      end if;

      mystyle := strtoupper (mystyle);

      if (instr (mystyle, 'U') > 0)
      then
         underline := true;
         mystyle := str_replace ('U', '', mystyle);
      else
         underline := false;
      end if;

      if (mystyle = 'IB')
      then
         mystyle := 'BI';
      end if;

      if (mysize = 0)
      then
         mysize := fontsizept;
      end if;

      -- Test if font is already selected
      if (fontfamily = myfamily and fontstyle = mystyle and fontsizept = mysize
         )
      then
         return;
      end if;

      -- Test if used for the first time
      fontkey := nvl (myfamily || mystyle, '');

      --if(not fontsExists(fontkey)) then
      if (not fonts.exists (fontkey))
      then
         -- Check if one of the standard fonts
         if (corefonts.exists (fontkey))
         then
            --if(not pdf_charwidthsExists(fontkey)) then
            if (not pdf_charwidths.exists (fontkey))
            then
               -- Load metric file
               myfontfile := myfamily;

               if (myfamily = 'times' or myfamily = 'helvetica')
               then
                  myfontfile :=
                                             myfontfile || strtolower (mystyle);
               end if;

               --
               p_includefont (fontkey);

               --
               if (not pdf_charwidthsexists (fontkey))
               then
                  error ('Could not include font metric file');
               end if;
            end if;

            fontcount := nvl (fonts.count, 0) + 1;
            fonts (fontkey).i := fontcount;
            fonts (fontkey).type := 'core';
            fonts (fontkey).name := corefonts (fontkey);
            fonts (fontkey).up := -100;
            fonts (fontkey).ut := 50;
            fonts (fontkey).cw := pdf_charwidths (fontkey);
         else
            error ('Undefined font: ' || myfamily || ' ' || mystyle);
         end if;
      end if;

      -- Select it
      fontfamily := myfamily;
      fontstyle := mystyle;
      fontsizept := mysize;
      fontsize := mysize / k;
      -- if(fontsExists(fontkey)) then
      currentfont := fonts (fontkey);

      -- end if;
      if (page > 0)
      then
         p_out (   'BT /F'
                || currentfont.i
                || ' '
                || tochar (fontsizept, 2)
                || ' Tf ET'
               );
      end if;
   end setfont;

----------------------------------------------------------------------------------------
   function getstringwidth (
      pstr                                varchar2
   )
      return number
   is
      charsetwidth                  charset;
      w                             number;
      lg                            number;
      wdth                          number;
      c                             car;
   begin
      -- Get width of a string in the current font
      charsetwidth := currentfont.cw;
      w := 0;
      lg:= strlen (pstr);

      for i in 1 .. lg
      loop
         wdth := 0;
         c := substr (pstr, i, 1);
         --if (charSetWidth.exists(c)) then
         wdth := charsetwidth (c);
         --end if;
         w := w + wdth;
      end loop;

      return w * fontsize / 1000;
   end getstringwidth;

----------------------------------------------------------------------------------------
   procedure setfontsize (
      psize                               number
   )
   is
   begin
      -- Set font size in points
      if (fontsizept = psize)
      then
         return;
      end if;

      fontsizept := psize;
      fontsize := psize / k;

      if (page > 0)
      then
         p_out (   'BT /F'
                || currentfont.i
                || ' '
                || tochar (fontsizept, 2)
                || ' Tf ET'
               );
      end if;
   end setfontsize;

----------------------------------------------------------------------------------------
   procedure cell (
      pw                                  number
    , ph                                  number default 0
    , ptxt                                varchar2 default ''
    , pborder                             varchar2 default '0'
    , pln                                 number default 0
    , palign                              varchar2 default ''
    , pfill                               number default 0
    , plink                               varchar2 default ''
   )
   is
      mypw                          number := pw;
      myk                           k%type := k;
      myx                           x%type := x;
      myy                           y%type := y;
      myws                          ws%type := ws;
      mys                           txt;
      myop                          txt;
      mydx                          number;
      mytxt2                        txt;
   begin
      null;

      -- Output a cell
      if ((y + ph > pagebreaktrigger) and not infooter and acceptpagebreak ()
         )
      then
         -- Automatic page break
         if (myws > 0)
         then
            ws := 0;
            p_out ('0 Tw');
         end if;

         addpage (curorientation);
         x := myx;

         if (myws > 0)
         then
            ws := myws;
            p_out (tochar (myws * myk, 3) || ' Tw');
         end if;
      end if;

      if (mypw = 0)
      then
         mypw := w - rmargin - x;
      end if;

      mys:= '';

      if (pfill = 1 or pborder = '1')
      then
         if (pfill = 1)
         then
            if (pborder = '1')
            then
               myop := 'B';
            else
               myop := 'f';
            end if;
         else
            myop := 'S';
         end if;

         mys :=
               tochar (x * myk, 2)
            || ' '
            || tochar ((h - y) * myk, 2)
            || ' '
            || tochar (mypw * myk, 2)
            || ' '
            || tochar (-ph * myk, 2)
            || ' re '
            || myop
            || ' ';
      end if;

      if (is_string (pborder))
      then
         myx := x;
         myy := y;

         if (instr (pborder, 'L') > 0)
         then
            mys :=
                  mys
               || tochar (myx * myk, 2)
               || ' '
               || tochar ((h - myy) * myk, 2)
               || ' m '
               || tochar (myx * myk, 2)
               || ' '
               || tochar ((h - (myy + ph)) * myk, 2)
               || ' l S ';
         end if;

         if (instr (pborder, 'T') > 0)
         then
            mys :=
                  mys
               || tochar (myx * myk, 2)
               || ' '
               || tochar ((h - myy) * myk, 2)
               || ' m '
               || tochar ((myx + mypw) * myk, 2)
               || ' '
               || tochar ((h - myy) * myk, 2)
               || ' l S ';
         end if;

         if (instr (pborder, 'R') > 0)
         then
            mys :=
                  mys
               || tochar ((myx + mypw) * myk, 2)
               || ' '
               || tochar ((h - myy) * myk, 2)
               || ' m '
               || tochar ((myx + mypw) * myk, 2)
               || ' '
               || tochar ((h - (myy + ph)) * myk, 2)
               || ' l S ';
         end if;

         if (instr (pborder, 'B') > 0)
         then
            mys :=
                  mys
               || tochar (myx * myk, 2)
               || ' '
               || tochar ((h - (myy + ph)) * myk, 2)
               || ' m '
               || tochar ((myx + mypw) * myk, 2)
               || ' '
               || tochar ((h - (myy + ph)) * myk, 2)
               || ' l S ';
         end if;
      end if;

      if ptxt is not null
      then
         if (palign = 'R')
         then
            mydx :=
                                         mypw - cmargin - getstringwidth (ptxt);
         elsif (palign = 'C')
         then
            mydx := (mypw - getstringwidth (ptxt)) / 2;
         elsif (palign = 'M')
         then
            mydx := (mypw - cmargin) / 2;
         else
            mydx := cmargin;
         end if;

         if (colorflag)
         then
            mys := mys || 'q ' || textcolor || ' ';
         end if;

         -- myTXT2 := str_replace(')','\\)',str_replace('(','\\(',str_replace('\\','\\\\',ptxt)));
         -- myTXT2 := str_replace('\\','\\\\',ptxt);
         mytxt2 :=
            str_replace (')'
                       , '\)'
                       , str_replace ('?'
                                    , '\?'
                                    , str_replace ('('
                                                 , '\('
                                                 , str_replace ('\', '\\', ptxt)
                                                  )
                                     )
                        );
         mys :=
               mys
            || 'BT '
            || tochar ((x + mydx) * myk, 2)
            || ' '
            || tochar ((h - (y + .5 * ph + .3 * fontsize)) * myk, 2)
            || ' Td ('
            || mytxt2
            || ') Tj ET';

         if (underline)
         then
            mys :=
                  mys
               || ' '
               || p_dounderline (x + mydx, y + .5 * ph + .3 * fontsize, ptxt);
         end if;

         if (colorflag)
         then
            mys := mys || ' Q';
         end if;

         if (not empty (plink))
         then
            link (x + mydx
                , y + .5 * ph - .5 * fontsize
                , getstringwidth (ptxt)
                , fontsize
                , plink
                 );
         end if;
      end if;

      if (not empty (mys))
      then
         p_out (mys);
      end if;

      lasth := ph;

      if (pln > 0)
      then
         -- Go to next line
         y := y + ph;

         if (pln = 1)
         then
            x := lmargin;
         end if;
      else
         x := x + mypw;
      end if;
   exception
      when others
      then
         error ('MultiCell : ' || sqlerrm);
   end cell;

----------------------------------------------------------------------------------------
-- MultiCell : Output text with automatic or explicit line breaks
-- param phMax : give the max height for the multicell. (0 if non applicable)
-- if ph is null : the minimum height is the value of the property LineSpacing
----------------------------------------------------------------------------------------
   procedure multicell (
      pw                                  number
    , ph                                  number default 0
    , ptxt                                varchar2
    , pborder                             varchar2 default '0'
    , palign                              varchar2 default 'J'
    , pfill                               number default 0
    , phmax                               number default 0
   )
   is
      charsetwidth                  charset;
      mypw                          number := pw;
      myborder                      word := pborder;
      mys                           txt;
      mynb                          number;
      wmax                          number;
      myb                           txt;
      myb2                          txt;
      sep                           number := -1;
--  i number := 0;
--  j number := 0;
      i                             number := 1;
      j                             number := 1;
      l                             number := 0;
      ns                            number := 0;
      nl                            number := 1;
      carac                         word;
      lb_skip                       boolean := false;
      ls                            number;
      cumulativeheight              number := 0;
      myh                           number := ph;
   begin
      -- Output text with automatic or explicit line breaks

      -- see if we need to set Height to the minimum linespace
      if (myh = 0)
      then
         myh := getlinespacing;
      end if;

      charsetwidth := currentfont.cw;

      if (mypw = 0)
      then
         mypw := w - rmargin - x;
      end if;

      wmax := (mypw - 2 * cmargin) * 1000 / fontsize;
      mys := str_replace (chr (13), '', ptxt);
      mynb := strlen (mys);

      if (mynb > 0 and substr (mys, -1) = chr (10))
      then
         mynb := mynb - 1;
      end if;

      myb := 0;

      if (myborder is not null)
      then
         if (myborder = '1')
         then
            myborder := 'LTRB';
            myb := 'LRT';
            myb2 := 'LR';
         else
            myb2 := '';

            if (instr (myborder, 'L') > 0)
            then
               myb2 := myb2 || 'L';
            end if;

            if (instr (myborder, 'R') > 0)
            then
               myb2 := myb2 || 'R';
            end if;

            if (instr (myborder, 'T') > 0)
            then
               myb := myb2 || 'T';
            else
               myb := myb2;
            end if;
         end if;
      end if;

      while (i <= mynb)
      loop
         lb_skip := false;
         -- Get next character
         carac := substr (mys, i, 1);

         if (carac = chr (10))
         then
            -- Explicit line break
            if (ws > 0)
            then
               ws := 0;
               p_out ('0 Tw');
            end if;

            cell (mypw, myh, substr (mys, j, i - j), myb, 2, palign, pfill);
            cumulativeheight := cumulativeheight + myh;
            i := i + 1;
            sep := -1;
            j := i;
            l := 0;
            ns:= 0;
            nl:= nl + 1;

            if (myborder is not null and nl = 2)
            then
               myb := myb2;
            end if;

            -- si on passe là on continue à la prochaine itération de la boucle
            -- en PHP il y avait l'instruction "continue" .
            lb_skip := true;
         end if;

         if (not lb_skip)
         then
            if (carac = ' ')
            then
               sep := i;
               ls := l;
               ns := ns + 1;
            end if;

            l := l + charsetwidth (carac);

            if (l > wmax)
            then
               -- Automatic line break
               if (sep = -1)
               then
                  if (i = j)
                  then
                     i := i + 1;
                  end if;

                  if (ws > 0)
                  then
                     ws := 0;
                     p_out ('0 Tw');
                  end if;

                  cell (mypw, myh, substr (mys, j, i - j), myb, 2, palign
                      , pfill);
               else
                  if (palign = 'J')
                  then
                     if (ns > 1)
                     then
                        ws :=
                                       (wmax - ls) / 1000 * fontsize
                                       / (ns - 1);
                     else
                        ws := 0;
                     end if;

                     p_out ('' || tochar (ws * k, 3) || ' Tw');
                  end if;

                  cell (mypw
                      , myh
                      , substr (mys, j, sep - j)
                      , myb
                      , 2
                      , palign
                      , pfill
                       );
                  i := sep + 1;
               end if;

               cumulativeheight := cumulativeheight + myh;
               sep := -1;
               j := i;
               l := 0;
               ns := 0;
               nl := nl + 1;

               if (myborder is not null and nl = 2)
               then
                  myb := myb2;
               end if;
            else
               i := i + 1;
            end if;
         end if;
      end loop;

      -- Last chunk
      if (ws > 0)
      then
         ws := 0;
         p_out ('0 Tw');
      end if;

      if (myborder is not null and instr (myborder, 'B') > 0)
      then
         if (phmax > 0)
         then
            if (cumulativeheight >= phmax)
            then
               myb := myb || 'B';
            end if;
         else
            myb := myb || 'B';
         end if;
      end if;

      cell (mypw, myh, substr (mys, j, i - j), myb, 2, palign, pfill);
      cumulativeheight := cumulativeheight + myh;

      -- add an empty cell if phMax is not reached.
      if (phmax > 0)
      then
         if (cumulativeheight < phmax)
         then
            -- dealing with the bottom border.
            if (myborder is not null and instr (myborder, 'B') > 0)
            then
               myb := myb || 'B';
            end if;

            cell (mypw, phmax - cumulativeheight, null, myb, 2, palign, pfill);
         end if;
      end if;

      x := lmargin;
   exception
      when others
      then
         error ('MultiCell : ' || sqlerrm);
   end multicell;

----------------------------------------------------------------------------------------
   procedure image (
      pfile                               varchar2
    , px                                  number
    , py                                  number
    , pwidth                              number default 0
    , pheight                             number default 0
    , ptype                               varchar2 default null
    , plink                               varchar2 default null
   )
   is
      myfile                        varchar2 (2000) := pfile;
      -- myType varchar2(256) := pType;
      myw                           number := pwidth;
      myh                           number := pheight;
      -- pos number;
      info                          recimage;
   begin
      --Put an image on the page
      if (not imageexists (myfile))
      then
         --First use of image, get info
         info := p_parseimage (myfile);
         info.i := nvl (images.count, 0) + 1;
         images (lower (myfile)) := info;
      else
         info := images (lower (myfile));
      end if;

      --Automatic width and height calculation if needed
      if (myw = 0 and myh = 0)
      then
         --Put image at 72 dpi
         myw := info.w / k;
         myh := info.h / k;
      end if;

      if (myw = 0)
      then
         myw := myh * info.w / info.h;
      end if;

      if (myh = 0)
      then
         myh := myw * info.h / info.w;
      end if;

      p_out (   'q '
             || tochar (myw * k, 2)
             || ' 0 0 '
             || tochar (myh * k, 2)
             || ' '
             || tochar (px * k, 2)
             || ' '
             || tochar ((h - (py + myh)) * k, 2)
             || ' cm /I'
             || to_char (info.i)
             || ' Do Q'
            );

      if (plink is not null)
      then
         link (px, py, myw, myh, plink);
      end if;
   exception
      when others
      then
         error ('image : ' || sqlerrm);
   end image;

/* THIS PROCEDURE HANGS UP ........... */
----------------------------------------------------------------------------------------
   procedure write (
      ph                                  varchar2
    , ptxt                                varchar2
    , plink                               varchar2 default null
   )
   is
      charsetwidth                  charset;
      myw                           number;
                          -- remaining width from actual position in user units
      mywmax                        number;              -- remaining cellspace
      s                             bigtext;
      c                             word;
      nb                            pls_integer;
      sep                           pls_integer;
      i                             pls_integer;
      j                             pls_integer;
      l                             pls_integer;
      lsep                          pls_integer;
      lastl                         pls_integer;
   begin
      -- Output text in flowing mode
      charsetwidth := currentfont.cw;
      myw := w - rmargin - x;
      mywmax := (myw - 2 * cmargin) * 1000 / fontsize;
      s := str_replace (chr (13), '', ptxt);
      nb := strlen (s);
      sep := -1;
                          -- no blank space encountered, position of last blank
      i := 1;                      -- running position
      j := 1;
                            -- last remembered position , start for next output
      l := 0;      -- string length since last written
      lsep := 0;                -- position of last blank
      lastl := 0;                -- length till that blank

      -- Loop over all characters
      while i <= nb
      loop
         -- Get next character
         c := substr (s, i, 1);

         -- Explicit line break
         if (c = chr (10))
         then
            cell (myw, ph, substr (s, j, i - j), 0, 1, '', 0, plink);
            -- positioned at beginning of new line
            i := i + 1;
            sep := -1;
            j := i;
            l := 0;
            myw := w - rmargin - x;
            mywmax := (myw - 2 * cmargin) * 1000 / fontsize;
                                                                  -- whole line
         else
            if c = ' '
            then
               sep := i;
               lsep := 0;
               lastl := l;
            else
               lsep := lsep + charsetwidth (c);
            end if;

            l := l + charsetwidth (c);

            if l > mywmax
            then
               -- Automatic line break
               if sep = -1
               then                                                   -- forced
                  cell (myw, ph, substr (s, j, i - j + 1), 0, 1, '', 0, plink);
                  i := i + 1;
                  j := i;
                  l := 0;
               else                                        -- wrap at last blank
                  cell (myw, ph, substr (s, j, sep - j), 0, 1, '', 0, plink);
                  i := sep + 1;
                  j := i;
                  sep := -1;
                  l := lsep - (mywmax - lastl);
                                     -- rest remaining space from previous line
                                     -- WHY ????
               end if;

               myw := w - rmargin - x;
               mywmax :=
                                           (myw - 2 * cmargin) * 1000 / fontsize;
            else
               i := i + 1;
            end if;
         end if;
      end loop;

      -- Last chunk
      if (i != j)
      then
         cell ((l + 2 * cmargin) / 1000 * fontsize
             , ph
             , substr (s, j)
             , 0
             , 0
             , ''
             , 0
             , plink
              );
      end if;
   exception
      when others
      then
         error ('write : ' || sqlerrm);
   end write;

   procedure print (
      pblob                      in out   blob
    , pstring                             varchar2
   )
   is
   begin
      dbms_lob.writeappend (pblob
                          , length (pstring)
                          , utl_raw.cast_to_raw (pstring)
                           );
   exception
      when others
      then
         error ('print : ' || sqlerrm);
   end print;

----------------------------------------------------------------------------------------
   procedure output (
      pblob                      in out   blob
    , pname                               varchar2 default null
    , pdest                               varchar2 default null
   )
   is
      myname                        word := pname;
      mydest                        word := pdest;
      v_clob                        clob;
      v_blob                        blob;
      v_in                          pls_integer;
      v_out                         pls_integer;
      v_lang                        pls_integer;
      v_warning                     pls_integer;
      v_len                         pls_integer;
   begin
      dbms_lob.createtemporary (v_blob, false, dbms_lob.session);

      -- Output PDF to some destination
      -- Finish document if necessary
      if state < 3
      then
         closepdf ();
      end if;

      mydest := strtoupper (mydest);

      if (mydest is null)
      then
         if (myname is null)
         then
            myname := 'doc.pdf';
            mydest := 'I';
         else
            mydest := 'D';
         end if;
      end if;

      if (mydest = 'I')
      then
         -- restitution du contenu...
         v_len := 1;

         for i in pdfdoc.first .. pdfdoc.last
         loop
            v_clob := to_clob (pdfdoc (i));
            pdfdoc (i) := null;              -- clear the table

            if v_clob is not null
            then
               v_in := 1;
               v_out := 1;
               v_lang := 0;
               v_warning := 0;
               v_len := dbms_lob.getlength (v_clob);
               dbms_lob.converttoblob (v_blob
                                     , v_clob
                                     , v_len
                                     , v_in
                                     , v_out
                                     , dbms_lob.default_csid
                                     , v_lang
                                     , v_warning
                                      );
               dbms_lob.append (pblob, dbms_lob.substr (v_blob, v_len));
            end if;
         end loop;
      elsif (mydest = 'D')
      then
         -- restitution du contenu...
         for i in pdfdoc.first .. pdfdoc.last
         loop
            print (pblob, pdfdoc (i));
         end loop;
      elsif (mydest = 'S')
      then
         print (pblob, 'text/html');

         -- Return as a string
         for i in pdfdoc.first .. pdfdoc.last
         loop
            print (pblob
                 , replace (replace (replace (pdfdoc (i), '<', '&lt;')
                                   , '>'
                                   , '&gt;'
                                    )
                          , chr (10)
                          , '<br/>'
                           )
                  );
         end loop;
      else
         error ('Incorrect output destination: ' || mydest);
      end if;

      dbms_lob.freetemporary (v_blob);
   exception
      when others
      then
         error ('Output : ' || sqlerrm);
   end output;
end pdfblob; 
/

