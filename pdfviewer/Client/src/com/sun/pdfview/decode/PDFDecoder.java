/*
 * $Id: PDFDecoder.java,v 1.3 2009/01/03 17:23:30 tomoke Exp $
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

import java.io.IOException;
import java.nio.ByteBuffer;

import com.sun.pdfview.PDFObject;
import com.sun.pdfview.PDFParseException;

/**
 * A PDF Decoder encapsulates all the methods of decoding a stream of bytes
 * based on all the various encoding methods.
 * <p>
 * You should use the decodeStream() method of this object rather than using
 * any of the decoders directly.
 */
public class PDFDecoder {

    /** Creates a new instance of PDFDecoder */
    private PDFDecoder() {
    }

    /**
     * decode a byte[] stream using the filters specified in the object's
     * dictionary (passed as argument 1).
     * @param dict the dictionary associated with the stream
     * @param streamBuf the data in the stream, as a byte buffer
     */
    public static ByteBuffer decodeStream(PDFObject dict, ByteBuffer streamBuf)
            throws IOException {
        PDFObject encoding = dict.getDictRef("Filter");
        if (encoding != null) {
            // it's the name of a filter, or an array of filter names
            PDFObject ary[];
            PDFObject params[];
            if (encoding.getType() == PDFObject.NAME) {
                ary = new PDFObject[1];
                ary[0] = encoding;
                params = new PDFObject[1];
                params[0] = dict.getDictRef("DecodeParms");
            } else {
                ary = encoding.getArray();
                PDFObject parmsobj = dict.getDictRef("DecodeParms");
                if (parmsobj != null) {
                    params = parmsobj.getArray();
                } else {
                    params = new PDFObject[ary.length];
                }
            }
            for (int i = 0; i < ary.length; i++) {
                String enctype = ary[i].getStringValue();
                if (enctype == null) {
                } else if (enctype.equals("FlateDecode") || enctype.equals("Fl")) {
                    streamBuf = FlateDecode.decode(dict, streamBuf, params[i]);
                } else if (enctype.equals("LZWDecode") || enctype.equals("LZW")) {
                    streamBuf = LZWDecode.decode(streamBuf, params[i]);
                } else if (enctype.equals("ASCII85Decode") || enctype.equals("A85")) {
                    streamBuf = ASCII85Decode.decode(streamBuf, params[i]);
                } else if (enctype.equals("ASCIIHexDecode") || enctype.equals("AHx")) {
                    streamBuf = ASCIIHexDecode.decode(streamBuf, params[i]);
                } else if (enctype.equals("DCTDecode") || enctype.equals("DCT")) {
                    streamBuf = DCTDecode.decode(dict, streamBuf, params[i]);
                } else if (enctype.equals("CCITTFaxDecode") || enctype.equals("CCF")) {
                    streamBuf = CCITTFaxDecode.decode(dict, streamBuf, params[i]);
                } else {
                    throw new PDFParseException("Unknown coding method:" + ary[i].getStringValue());
                }
            }
        }

        return streamBuf;
    }
}
