--[[
	stb_truetype Binding

	A binding to stb_truetype, included in coeus_aux.
]]

local C = (...)
local Coeus = C:Get("Coeus")
local ffi = require("ffi")
local stb_truetype = Coeus.Bindings.coeus_aux

ffi.cdef([[
// stb_truetype.h - v0.8b - public domain
// authored from 2009-2013 by Sean Barrett / RAD Game Tools
// Sean Barrett is a god, BOW DOWN TO HIM

typedef unsigned char   stbtt_uint8;
typedef signed   char   stbtt_int8;
typedef unsigned short  stbtt_uint16;
typedef signed   short  stbtt_int16;
typedef unsigned int    stbtt_uint32;
typedef signed   int    stbtt_int32;

typedef char stbtt__check_size32[sizeof(stbtt_int32)==4 ? 1 : -1];
typedef char stbtt__check_size16[sizeof(stbtt_int16)==2 ? 1 : -1];

typedef struct
{
   unsigned short x0,y0,x1,y1;
   float xoff,yoff,xadvance;   
} stbtt_bakedchar;

extern int stbtt_BakeFontBitmap(const unsigned char *data, int offset,
                                float pixel_height,
                                unsigned char *pixels, int pw, int ph,
                                int first_char, int num_chars,
                                stbtt_bakedchar *chardata);

typedef struct
{
   float x0,y0,s0,t0;
   float x1,y1,s1,t1;
} stbtt_aligned_quad;

extern void stbtt_GetBakedQuad(stbtt_bakedchar *chardata, int pw, int ph,
                               int char_index,
                               float *xpos, float *ypos,
                               stbtt_aligned_quad *q,
                               int opengl_fillrule);

extern int stbtt_GetFontOffsetForIndex(const unsigned char *data, int index);

typedef struct stbtt_fontinfo
{
   void           * userdata;
   unsigned char  * data;            
   int              fontstart;       

   int numGlyphs;

   int loca,head,glyf,hhea,hmtx,kern;
   int index_map;
   int indexToLocFormat;
} stbtt_fontinfo;

extern int stbtt_InitFont(stbtt_fontinfo *info, const unsigned char *data, int offset);
int stbtt_FindGlyphIndex(const stbtt_fontinfo *info, int unicode_codepoint);
extern float stbtt_ScaleForPixelHeight(const stbtt_fontinfo *info, float pixels);
extern float stbtt_ScaleForMappingEmToPixels(const stbtt_fontinfo *info, float pixels);
extern void stbtt_GetFontVMetrics(const stbtt_fontinfo *info, int *ascent, int *descent, int *lineGap);
extern void stbtt_GetFontBoundingBox(const stbtt_fontinfo *info, int *x0, int *y0, int *x1, int *y1);
extern void stbtt_GetCodepointHMetrics(const stbtt_fontinfo *info, int codepoint, int *advanceWidth, int *leftSideBearing);
extern int  stbtt_GetCodepointKernAdvance(const stbtt_fontinfo *info, int ch1, int ch2);
extern int stbtt_GetCodepointBox(const stbtt_fontinfo *info, int codepoint, int *x0, int *y0, int *x1, int *y1);
extern void stbtt_GetGlyphHMetrics(const stbtt_fontinfo *info, int glyph_index, int *advanceWidth, int *leftSideBearing);
extern int  stbtt_GetGlyphKernAdvance(const stbtt_fontinfo *info, int glyph1, int glyph2);
extern int  stbtt_GetGlyphBox(const stbtt_fontinfo *info, int glyph_index, int *x0, int *y0, int *x1, int *y1);

enum {
  STBTT_vmove=1,
  STBTT_vline,
  STBTT_vcurve
};

typedef struct
{
  short x,y,cx,cy;
  unsigned char type,padding;
} stbtt_vertex;

extern int stbtt_IsGlyphEmpty(const stbtt_fontinfo *info, int glyph_index);
extern int stbtt_GetCodepointShape(const stbtt_fontinfo *info, int unicode_codepoint, stbtt_vertex **vertices);
extern int stbtt_GetGlyphShape(const stbtt_fontinfo *info, int glyph_index, stbtt_vertex **vertices);
extern void stbtt_FreeShape(const stbtt_fontinfo *info, stbtt_vertex *vertices);

extern void stbtt_FreeBitmap(unsigned char *bitmap, void *userdata);

extern unsigned char *stbtt_GetCodepointBitmap(const stbtt_fontinfo *info, float scale_x, float scale_y, int codepoint, int *width, int *height, int *xoff, int *yoff);
extern unsigned char *stbtt_GetCodepointBitmapSubpixel(const stbtt_fontinfo *info, float scale_x, float scale_y, float shift_x, float shift_y, int codepoint, int *width, int *height, int *xoff, int *yoff);
extern void stbtt_MakeCodepointBitmap(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, int codepoint);
extern void stbtt_MakeCodepointBitmapSubpixel(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, float shift_x, float shift_y, int codepoint);
extern void stbtt_GetCodepointBitmapBox(const stbtt_fontinfo *font, int codepoint, float scale_x, float scale_y, int *ix0, int *iy0, int *ix1, int *iy1);
extern void stbtt_GetCodepointBitmapBoxSubpixel(const stbtt_fontinfo *font, int codepoint, float scale_x, float scale_y, float shift_x, float shift_y, int *ix0, int *iy0, int *ix1, int *iy1);

extern unsigned char *stbtt_GetGlyphBitmap(const stbtt_fontinfo *info, float scale_x, float scale_y, int glyph, int *width, int *height, int *xoff, int *yoff);
extern unsigned char *stbtt_GetGlyphBitmapSubpixel(const stbtt_fontinfo *info, float scale_x, float scale_y, float shift_x, float shift_y, int glyph, int *width, int *height, int *xoff, int *yoff);
extern void stbtt_MakeGlyphBitmap(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, int glyph);
extern void stbtt_MakeGlyphBitmapSubpixel(const stbtt_fontinfo *info, unsigned char *output, int out_w, int out_h, int out_stride, float scale_x, float scale_y, float shift_x, float shift_y, int glyph);
extern void stbtt_GetGlyphBitmapBox(const stbtt_fontinfo *font, int glyph, float scale_x, float scale_y, int *ix0, int *iy0, int *ix1, int *iy1);
extern void stbtt_GetGlyphBitmapBoxSubpixel(const stbtt_fontinfo *font, int glyph, float scale_x, float scale_y,float shift_x, float shift_y, int *ix0, int *iy0, int *ix1, int *iy1);

typedef struct
{
   int w,h,stride;
   unsigned char *pixels;
} stbtt__bitmap;

extern void stbtt_Rasterize(stbtt__bitmap *result, float flatness_in_pixels, stbtt_vertex *vertices, int num_verts, float scale_x, float scale_y, float shift_x, float shift_y, int x_off, int y_off, int invert, void *userdata);

extern int stbtt_FindMatchingFont(const unsigned char *fontdata, const char *name, int flags);

enum {
	STBTT_MACSTYLE_DONTCARE     = 0,
	STBTT_MACSTYLE_BOLD         = 1,
	STBTT_MACSTYLE_ITALIC       = 2,
	STBTT_MACSTYLE_UNDERSCORE   = 4,
	STBTT_MACSTYLE_NONE         = 8   // <= not same as 0, this makes us check the bitfield is 0
};

extern int stbtt_CompareUTF8toUTF16_bigendian(const char *s1, int len1, const char *s2, int len2);
extern const char *stbtt_GetFontNameString(const stbtt_fontinfo *font, int *length, int platformID, int encodingID, int languageID, int nameID);

enum { // platformID
   STBTT_PLATFORM_ID_UNICODE   =0,
   STBTT_PLATFORM_ID_MAC       =1,
   STBTT_PLATFORM_ID_ISO       =2,
   STBTT_PLATFORM_ID_MICROSOFT =3
};

enum { // encodingID for STBTT_PLATFORM_ID_UNICODE
   STBTT_UNICODE_EID_UNICODE_1_0    =0,
   STBTT_UNICODE_EID_UNICODE_1_1    =1,
   STBTT_UNICODE_EID_ISO_10646      =2,
   STBTT_UNICODE_EID_UNICODE_2_0_BMP=3,
   STBTT_UNICODE_EID_UNICODE_2_0_FULL=4
};

enum { // encodingID for STBTT_PLATFORM_ID_MICROSOFT
   STBTT_MS_EID_SYMBOL        =0,
   STBTT_MS_EID_UNICODE_BMP   =1,
   STBTT_MS_EID_SHIFTJIS      =2,
   STBTT_MS_EID_UNICODE_FULL  =10
};

enum { // encodingID for STBTT_PLATFORM_ID_MAC; same as Script Manager codes
   STBTT_MAC_EID_ROMAN        =0,   STBTT_MAC_EID_ARABIC       =4,
   STBTT_MAC_EID_JAPANESE     =1,   STBTT_MAC_EID_HEBREW       =5,
   STBTT_MAC_EID_CHINESE_TRAD =2,   STBTT_MAC_EID_GREEK        =6,
   STBTT_MAC_EID_KOREAN       =3,   STBTT_MAC_EID_RUSSIAN      =7
};

enum { // languageID for STBTT_PLATFORM_ID_MICROSOFT; same as LCID...
       // problematic because there are e.g. 16 english LCIDs and 16 arabic LCIDs
   STBTT_MS_LANG_ENGLISH     =0x0409,   STBTT_MS_LANG_ITALIAN     =0x0410,
   STBTT_MS_LANG_CHINESE     =0x0804,   STBTT_MS_LANG_JAPANESE    =0x0411,
   STBTT_MS_LANG_DUTCH       =0x0413,   STBTT_MS_LANG_KOREAN      =0x0412,
   STBTT_MS_LANG_FRENCH      =0x040c,   STBTT_MS_LANG_RUSSIAN     =0x0419,
   STBTT_MS_LANG_GERMAN      =0x0407,   STBTT_MS_LANG_SPANISH     =0x0409,
   STBTT_MS_LANG_HEBREW      =0x040d,   STBTT_MS_LANG_SWEDISH     =0x041D
};

enum { // languageID for STBTT_PLATFORM_ID_MAC
   STBTT_MAC_LANG_ENGLISH      =0 ,   STBTT_MAC_LANG_JAPANESE     =11,
   STBTT_MAC_LANG_ARABIC       =12,   STBTT_MAC_LANG_KOREAN       =23,
   STBTT_MAC_LANG_DUTCH        =4 ,   STBTT_MAC_LANG_RUSSIAN      =32,
   STBTT_MAC_LANG_FRENCH       =1 ,   STBTT_MAC_LANG_SPANISH      =6 ,
   STBTT_MAC_LANG_GERMAN       =2 ,   STBTT_MAC_LANG_SWEDISH      =5 ,
   STBTT_MAC_LANG_HEBREW       =10,   STBTT_MAC_LANG_CHINESE_SIMPLIFIED =33,
   STBTT_MAC_LANG_ITALIAN      =3 ,   STBTT_MAC_LANG_CHINESE_TRAD =19
};
]])

return stb_truetype