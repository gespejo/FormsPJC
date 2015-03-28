/*
 * $Id: CCITTFaxDecode.java,v 1.4 2009/01/06 22:36:37 tomoke Exp $
 *
 * Copyright 2004 Sun Microsystems, Inc., 4150 Network Circle,
 * Santa Clara, California 95054, U.S.A. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */
package com.sun.pdfview.decode;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.ByteBuffer;

import com.sun.pdfview.PDFObject;
import com.sun.pdfview.PDFParseException;

/**
 * Decode CCITT Group 4 format coding into a byte array
 * @author Mike Wessler
 */
public class CCITTFaxDecode {
    // Group-3 coding:
    // 1-d coding: each code word represents a segment of white or black
    // white and black runs alternate.  white run to start.
    // 1728 pixels across
    // 0-63:  1 terminating code word
    // 64-1728: makeup word+terminating word
    // EOL: 0000 0000 0001  (some number of 0's >10, followed by a 1)
    // FILL (between data and EOL: variable count of 0's
    // ends with 6 consecutive EOLs.
    // code words in file CCITTCodes

    class CCITTTreeNode {
    }

    class CCITTTreeBranch extends CCITTTreeNode {

        CCITTTreeNode zero;
        CCITTTreeNode one;
    }

    class CCITTTreeLeaf extends CCITTTreeNode {

        int code;

        public CCITTTreeLeaf(int code) {
            this.code = code;
        }
    }
    static CCITTTreeNode blackTree;
    static CCITTTreeNode whiteTree;

    /**
     * read in the file "CCITTCodes" to generate two decision trees.
     */
    private void createTrees() throws IOException {
        InputStream is = getClass().getResourceAsStream("CCITTCodes");
        
        if (is.available() != 0 ){ 
        BufferedReader br = new BufferedReader(new InputStreamReader(is));
        String line;
        CCITTTreeNode base = null;
        while ((line = br.readLine()) != null) {
            // parse that line
            if (line.startsWith("# BLACK")) {
                base = blackTree = new CCITTTreeBranch();
            } else if (line.startsWith("# WHITE")) {
                base = whiteTree = new CCITTTreeBranch();
            } else if (!line.startsWith("#") && line.length() > 0) {
                // trace path of bits
                int scanbit = 0;
                char thisChar = line.charAt(scanbit++);
                char nextChar;
                CCITTTreeBranch tn = (CCITTTreeBranch) base;
                while ((nextChar = line.charAt(scanbit++)) != ' ') {
                    if (thisChar == '0') {
                        if (tn.zero == null) {
                            tn.zero = new CCITTTreeBranch();
                        }
                        if (tn.zero instanceof CCITTTreeLeaf) {
                            throw new PDFParseException("Bad form: " + line + " has a leaf at bit number " + (scanbit - 1));
                        }
                        tn = (CCITTTreeBranch) tn.zero;
                    } else {
                        if (tn.one == null) {
                            tn.one = new CCITTTreeBranch();
                        }
                        if (tn.one instanceof CCITTTreeLeaf) {
                            throw new PDFParseException("Bad form: " + line + " has a leaf at bit number " + (scanbit - 1));
                        }
                        tn = (CCITTTreeBranch) tn.one;
                    }
                    thisChar = nextChar;
                }
                int code = Integer.parseInt(line.substring(scanbit));
                if (thisChar == '0') {
                    if (tn.zero != null) {
                        throw new PDFParseException("Bad form: last char of " + line + " is already occupied in the tree");
                    }
                    tn.zero = new CCITTTreeLeaf(code);
                } else {
                    if (tn.one != null) {
                        throw new PDFParseException("Bad form: last char of " + line + " is already occupied in the tree");
                    }
                    tn.one = new CCITTTreeLeaf(code);
                }
            }
        }
        }
    }
    private ByteBuffer buf;
    private int bytenum = 0;
    private int bitnum = 8;
    private byte bits;

    // color change boundaries.  refline[0](=0) -> refline[1] = white
    // even digits are start of white ranges, odds are start of black ranges
    private int refline[];  // indices of color changes on reference line
    private int reflen;     // size of refline (may not need this)
    private int refloc;     // where the current spot is within refline
    private int curline[];  // indices of color changes on current line
    private int curlen;     // length of curline
    private int prevspan;   // what color we're drawing (derive from curlen?)
    private int nlines;     // what line # we're on
    private int WHITEBIT = 0;
    private ByteArrayOutputStream baos;
    private int destbyte;   // the byte
    private int bitsremaining = 8;

    /**
     * initialize the decoder with a byte buffer in
     * CCITT Group 4 Fax form
     */
    private CCITTFaxDecode(ByteBuffer buf) throws IOException {
        if (blackTree == null) {
            createTrees();
        }

        // copy the data
        // [ JK FIXME this could probably

        this.buf = buf;
        bitnum = 0;
        bits = buf.get(0);
        bytenum = 1;
    }

    private void invert() {
        WHITEBIT = 1 - WHITEBIT;
    }

    /**
     * get the next bit from the stream.
     * @return true if the next bit is 1, false if it's a 0
     */
    private boolean nextBit() {
        if (bitnum == 8) {
            bitnum = 0;
            try {
                bits = buf.get(bytenum++);
            } catch (RuntimeException e) {
                System.out.println("Error: bytenum=" + bytenum + " of " + buf.limit());
                throw e;
            }
        }
        bitnum++;
        boolean value = (bits & 0x80) != 0;//(bits&1)!=0;//
        bits <<= 1;//bits>>=1;//
        //	System.out.print(value?"1":"0");
        return value;
    }

    /**
     * get the next code word from the stream.
     * @param base which tree to scan (black or white)
     * @return the code word
     */
    private int nextCode(CCITTTreeNode base) throws PDFParseException {
        while (!(base instanceof CCITTTreeLeaf)) {
            if (nextBit()) {
                base = ((CCITTTreeBranch) base).one;
            } else {
                base = ((CCITTTreeBranch) base).zero;
            }
            if (base == null) {
                System.out.println(" bleah.");
                throw new PDFParseException("Bad code word!");
            }
        }
        //	System.out.println(" ="+((CCITTTreeLeaf)base).code);
        return ((CCITTTreeLeaf) base).code;
    }

    /**
     * get the next distance encoded in the stream.  Distances can
     * consist of one or two code words.
     * @param base which tree to scan (black or white)
     * @return the distance encoded
     */
    private int nextDist(CCITTTreeNode base) throws PDFParseException {
        int tot, code;
        tot = code = nextCode(base);
        while (code >= 64) {
            code = nextCode(base);
            tot += code;
        }
        return tot;
    }

    /**
     * continue scanning bits until the end of an encoded line
     * is reached.  This method is no longer used.
     */
    private void skipToEOL() {
        int bitcount = 0;
        int totcount = 0;
        while (true) {
            if (!nextBit()) {
                bitcount++;
            } else {
                if (bitcount > 10) {
                    break;
                }
                bitcount = 0;
            }
            totcount++;
            if ((totcount & 7) == 0) {
                System.out.print(" ");
            }
            if ((totcount & 63) == 0) {
                System.out.println();
            }
        }
//	System.out.println("\nSkipped "+(totcount/8)+" bytes.  Bytenum is now "+bytenum);
    }

    /**
     * add a given number of pixels of a particular color to
     * the current line.  This is performed in intermediate
     * form, recording only the locations of the color changes.
     * 
     */
    private void addColor(int color, int num) {
        if (prevspan == color) {
            // add the new length to the previous length
            curline[curlen - 1] += num;
        //	    System.out.println("Added "+num+" to current color ("+color+") for a total of "+curline[curlen-1]);
        } else {
            if (curlen == curline.length) {
                int nline[] = new int[curline.length * 2];
                System.arraycopy(curline, 0, nline, 0, curline.length);
                curline = nline;
            }
            curline[curlen] = curline[curlen - 1] + num;
            curlen++;
            prevspan = color;
        //	    System.out.println("New span, width="+num+" for color "+color+" for a total of "+curline[curlen-1]);
        }
    }

    /**
     * Find the B1 location for the previous line, given the A0 color.
     * See the description of CCITT codes for what this means.
     * @param a0color BLACK or WHITE
     * @return the B1 location
     */
    private int findB1(int a0color) {
        // a0pos= curline[curlen-1]
        // start search at refloc
        int start = curlen == 1 ? -1 : curline[curlen - 1];
        while (refline[refloc] <= start) {
            refloc++;
        }
        int scan = refloc;
        // match color:  refloc&1==0 means white
        if (((scan & 1) == 0) == (a0color == WHITE)) {
            scan++;
        }
        return refline[scan] - curline[curlen - 1];
    }

    /**
     * Find the B2 location for the previous line, given the A0 color.
     * See the description of CCITT codes for what this means.
     * @param a0color BLACK or WHITE
     * @return the B2 location
     */
    private int findB2(int a0color) {
        // a0pos= curline[curlen-1]
        // start search at refloc
        int start = curlen == 1 ? -1 : curline[curlen - 1];
        while (refline[refloc] <= start) {
            refloc++;
        }
        int scan = refloc;
        // match color:  refloc&1==0 means white
        if (((scan & 1) == 0) == (a0color == WHITE)) {
            scan++;
        }
        return refline[scan + 1] - curline[curlen - 1];
    }

    /**
     * dump actual black bits into the output stream.  Unlike
     * addColor(), this actually puts bits into the stream.
     * 
     * @param span the number of black pixels to add
     */
    private void stuffBlackBits(int span) {
        int num = span;
        int fillbits = (0xFF >> (8 - bitsremaining));
        destbyte |= (byte) fillbits;
        bitsremaining -= num;
        while (bitsremaining <= 0) {
            baos.write(destbyte);
            destbyte = 0xFF;
            bitsremaining += 8;
        }
        destbyte &= (0xFF << bitsremaining);
    }

    /**
     * dump actual white bits into the output stream.  Unlike
     * addColor(), this actually puts bits into the stream.
     * 
     * @param span the number of white pixels to add
     */
    private void stuffWhiteBits(int span) {
        // stuff blank bytes
        int num = span;
        bitsremaining -= num;  // bitsremaining might go negative!
        while (bitsremaining <= 0) {
            baos.write(destbyte);
            destbyte = 0;
            bitsremaining += 8;
        }
    }

    /**
     * interpret the intermediate span form to produce actual
     * bits for the line.
     * @param width unused (old error checking)
     * @param linenum unused (old error checking)
     */
    private void processLine(int width, int linenum) {
        for (int i = 1; i < reflen; i++) {
            int len = refline[i] - refline[i - 1];
            if (len > 0) {
                if ((i & 1) == WHITEBIT) {
                    stuffWhiteBits(len);
                } else {
                    stuffBlackBits(len);
                }
            }
        }
        stuffWhiteBits(bitsremaining % 8);
    }
    public static final int TWOD = 2;
    public static final int UNCOMPRESSED = 3;
    public static final int PASS = 4;
    public static final int VERTICAL = 5;
    public static final int HORIZONTAL = 6;
    public static final int BLACK = 1;
    public static final int WHITE = 0;

    /**
     * decode a line of output from the input
     * @param totlen how long in pixels the line is expected to be
     * @return how long the line actually was
     */
    private int decodeLine(int totlen) throws PDFParseException {
        // white starts!
        int linelen = 0;
        int mode = TWOD;
        int color = WHITE;
        int prevlen = 0;
        curline = new int[500];
        curlen = 0;
        curline[curlen++] = 0;
        prevspan = BLACK;
        refloc = 0;
        while (curline[curlen - 1] < totlen) {
            int len;
            /*
            if (mode==WHITE) {
            len= nextDist(whiteTree);
            if (len>0) {
            //		    addColor(WHITE, len);
            stuffWhiteBits(len);
            mode= BLACK;
            } else if (len==-2) {
            mode= UNCOMPRESSED;
            } else if (len<0) {
            break;
            }
            } else if (mode==BLACK) {
            len= nextDist(blackTree);
            if (len>0) {
            //		    addColor(BLACK, len);
            stuffBlackBits(len);
            linelen+= len;
            mode= WHITE;
            } else if (len==-2) {
            mode= UNCOMPRESSED;
            } else if (len<0) {
            break;
            }
            } else
             */
            if (mode == UNCOMPRESSED) {
                // code words are /0*1/ representing up to 5 zeros
                // 1->1 01->01... 000001->00000
                // stop words: 6 zeros-> nil, 7->0 ... 10->0000
                // bit after the stop word maps 1=black, 0=white
                int count = 0;
                while (!nextBit()) {
                    count++;
                }
                //		System.out.println(" (uncompressed)");
                if (count <= 5) {
                    //		    System.out.println("Adding "+count+" white"+(count==5?"":" + 1 black"));
                    addColor(WHITE, count);
                    if (count < 5) {
                        addColor(BLACK, 1);
                    }
                } else if (count <= 10) {
                    if (count > 6) {
                        addColor(WHITE, count - 6);
                    }
                    if (nextBit()) {
                        color = BLACK;
                    } else {
                        color = WHITE;
                    }
                    //		    System.out.println("Finishing with "+(count-6)+" white");
                    mode = TWOD;
                //		    System.out.println("  new mode="+((mode==WHITE)?"white":"black"));
                } else {
                    // end of line
                    break;
                }
            } else if (mode == TWOD) {
                // w/ respect to reference line
                int count = 0;
                while (!nextBit()) {
                    count++;
                }
                if (count == 2) {
                    //		    System.out.println(" HORIZONTAL MODE");
                    // HORIZONTAL MODE
                    for (int i = 0; i < 2; i++) {
                        if (color == WHITE) {
                            len = nextDist(whiteTree);
                            addColor(WHITE, len);
                            color = BLACK;
                        } else {
                            len = nextDist(blackTree);
                            addColor(BLACK, len);
                            color = WHITE;
                        }
                    }
                } else if (count == 3) {
                    // PASS MODE
                    //		    System.out.println(" PASS MODE");
                    len = findB2(color);
                    if (color == WHITE) {
                        addColor(WHITE, len);
                    } else {
                        addColor(BLACK, len);
                    }
                } else if (count == 6) {
                    // EXTENSION
                    // read the next 3 bits
                    int type = ((nextBit() ? 4 : 0) |
                            (nextBit() ? 2 : 0) |
                            (nextBit() ? 1 : 0));
                    //		    System.out.println(" EXTENSION <6>: "+type);
                    mode = UNCOMPRESSED;
                } else if (count == 0) {
                    // VERTICAL MODE, Directly underneath
                    //		    System.out.println(" VERTICAL (0)");
                    len = findB1(color);
                    if (color == WHITE) {
                        addColor(WHITE, len);
                        color = BLACK;
                    } else {
                        addColor(BLACK, len);
                        color = WHITE;
                    }
                } else if (count == 11) {
                    // EOL
                    break;
                } else {
                    int right = nextBit() ? 1 : -1;
                    // distance is 1=1 4=2, 5=3;
                    if (count == 1) {
                        len = right;
                    } else if (count == 4) {
                        len = right * 2;
                    } else if (count == 5) {
                        len = right * 3;
                    } else {
                        throw new PDFParseException("Bad code word! (" +
                                count + "), char=" +
                                bytenum + ", line=" + nlines +
                                ", insertion #" + curlen);
                    }
                    //		    System.out.println(" VERTICAL MODE ("+len+")");
                    len += findB1(color);
                    if (color == WHITE) {
                        addColor(WHITE, len);
                        color = BLACK;
                    } else {
                        addColor(BLACK, len);
                        color = WHITE;
                    }
                }
            }
            //	    System.out.println("Line length is now "+curline[curlen-1]+" at "+(curlen-1));
            if (curline[curlen - 1] > totlen) {
                throw new PDFParseException("Line went too long! (bytenum=" + bytenum + ", len=" + (curline[curlen - 1]) + " of " + totlen + ", prev=" + prevlen + ")");
            }
            prevlen = curline[curlen - 1];
        }
        addColor(WHITE, 0);
        addColor(BLACK, 0);
        addColor(WHITE, 0);
        // curline becomes refline
        refline = curline;
        reflen = curlen;
        return curline[curlen - 1];
    }

    /**
     * decode the output bitmap from the input array
     * @param len the expected length of each line
     * @return a byte array containing the packed pixels of the image
     */
    private ByteBuffer decode(int len, int rows) throws PDFParseException {
        long time = System.currentTimeMillis();
        baos = new ByteArrayOutputStream();
        refline = new int[3];
        refline[0] = 0;
        refline[1] = refline[2] = len;
        reflen = 3;
        nlines = 0;

        while (rows < 0 || nlines < rows) {
//	    System.out.println(bytenum);
            int linelen = decodeLine(len);
            //	    System.out.println("Line length= "+linelen);
            if (linelen == 0) {
                break;
            }
            processLine(len, nlines);
            nlines++;
        }
        //	PDFRenderContext.debug("Image was "+len+"x"+nlines, 2);
        //	PDFRenderContext.debug("Took "+((System.currentTimeMillis()-time)/1000.0)+" seconds, size="+baos.size(), 0);
        return ByteBuffer.wrap(baos.toByteArray());
    }

    /**
     * decode a buffer bits to a bitmap image using the CCITT
     * Group 4 fax encoding.
     * @param buf the input byte buffer
     * @param params the input parameters; must be a PDF dictionary
     *  that contains an entry for "Columns" describing how wide the
     *  image is in pixels.
     * @return a byte buffer describing the bits of the image.  Each
     *  line of the image will be padded to the next byte boundary.
     */
    protected static ByteBuffer decode(PDFObject dict, ByteBuffer buf,
            PDFObject params) throws IOException {
        //	PDFRenderContext.debug(params.toString(), 0);
        //	PDFRenderContext.debug("K: "+params.getDictRef("K")+", cols="+params.getDictRef("Columns"), 0);
        //	PDFRenderContext.debug("Stream contains "+ary.length+" bytes", 0);
        CCITTFaxDecode me = new CCITTFaxDecode(buf);
        int len = 1728;
        int rows = -1;
        boolean invert = false;
        PDFObject cols = params.getDictRef("Columns");
        if (cols != null) {
            len = cols.getIntValue();
        }
        PDFObject height = dict.getDictRef("Height");
        if (height != null) {
            rows = height.getIntValue();
        }
        PDFObject blackis1 = params.getDictRef("BlackIs1");
        if (blackis1 != null) {
            if (blackis1.getBooleanValue() == true) {
                me.invert();
            }
        }
        return me.decode(len, rows);
    }
}
