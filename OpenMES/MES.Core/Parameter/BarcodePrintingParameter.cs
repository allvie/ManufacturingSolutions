﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.ComponentModel;

namespace MES.Core.Parameter
{
    public class BarcodePrintingParameter : ParameterBase
    {
        public string PrinterName { get; set; }
        public string BarcodeFontName { get; set; }
        public int BarcodeFontSize { get; set; }
        public int BarcodeXPosition { get; set; }
        public int BarcodeYPosition { get; set; }
        public string CaptionFontName { get; set; }
        public int CaptionFontSize { get; set; }
        public int CaptionXPosition { get; set; }
        public int CaptionYPosition { get; set; }
        public bool IsPrintingCaption { get; set; }
        public int BarcodeImageHeight { get; set; }
        public int BarcodeImageWidth { get; set; }
        public BarcodeType BarcodeType { get; set; }

        //Width of the paper, in hundredths of an inch.
        public int BarcodeLabelPaperWidth { get; set; }

        //Height of the paper, in hundredths of an inch.
        public int BarcodeLabelPaperHeight { get; set; }
    }

    /// <summary>
    /// Enumerates barcode formats known to this package.
    /// </summary>
    /// <author>Sean Owen</author>
    [System.Flags]
    public enum BarcodeType
    {
        /// <summary>Aztec 2D barcode format.</summary>
        AZTEC = 1,

        /// <summary>CODABAR 1D format.</summary>
        CODABAR = 2,

        /// <summary>Code 39 1D format.</summary>
        CODE_39 = 4,

        /// <summary>Code 93 1D format.</summary>
        CODE_93 = 8,

        /// <summary>Code 128 1D format.</summary>
        CODE_128 = 16,

        /// <summary>Data Matrix 2D barcode format.</summary>
        DATA_MATRIX = 32,

        /// <summary>EAN-8 1D format.</summary>
        EAN_8 = 64,

        /// <summary>EAN-13 1D format.</summary>
        EAN_13 = 128,

        /// <summary>ITF (Interleaved Two of Five) 1D format.</summary>
        ITF = 256,

        /// <summary>MaxiCode 2D barcode format.</summary>
        MAXICODE = 512,

        /// <summary>PDF417 format.</summary>
        PDF_417 = 1024,

        /// <summary>QR Code 2D barcode format.</summary>
        QR_CODE = 2048,

        /// <summary>RSS 14</summary>
        RSS_14 = 4096,

        /// <summary>RSS EXPANDED</summary>
        RSS_EXPANDED = 8192,

        /// <summary>UPC-A 1D format.</summary>
        UPC_A = 16384,

        /// <summary>UPC-E 1D format.</summary>
        UPC_E = 32768,

        /// <summary>UPC/EAN extension format. Not a stand-alone format.</summary>
        UPC_EAN_EXTENSION = 65536,

        /// <summary>MSI</summary>
        MSI = 131072,

        /// <summary>Plessey</summary>
        PLESSEY = 262144,

        /// <summary>Intelligent Mail barcode</summary>
        IMB = 524288,

        /// <summary>
        /// UPC_A | UPC_E | EAN_13 | EAN_8 | CODABAR | CODE_39 | CODE_93 | CODE_128 | ITF | RSS_14 | RSS_EXPANDED
        /// without MSI (to many false-positives) and IMB (not enough tested, and it looks more like a 2D)
        /// </summary>
        All_1D = UPC_A | UPC_E | EAN_13 | EAN_8 | CODABAR | CODE_39 | CODE_93 | CODE_128 | ITF | RSS_14 | RSS_EXPANDED
    }
}
