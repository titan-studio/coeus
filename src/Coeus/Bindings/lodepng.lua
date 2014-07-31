local Coeus = ...
local ffi = require("ffi")
local lib = Coeus.Bindings.coeus_aux

ffi.cdef([[
/*
LodePNG version 20140624

Copyright (c) 2005-2014 Lode Vandevenne

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
*/

typedef enum LodePNGColorType
{
  LCT_GREY = 0,
  LCT_RGB = 2,
  LCT_PALETTE = 3,
  LCT_GREY_ALPHA = 4,
  LCT_RGBA = 6
} LodePNGColorType;

unsigned lodepng_decode_memory(unsigned char** out, unsigned* w, unsigned* h,
                               const unsigned char* in, size_t insize,
                               LodePNGColorType colortype, unsigned bitdepth);
unsigned lodepng_decode32(unsigned char** out, unsigned* w, unsigned* h,
                          const unsigned char* in, size_t insize);
unsigned lodepng_decode24(unsigned char** out, unsigned* w, unsigned* h,
                          const unsigned char* in, size_t insize);
unsigned lodepng_decode_file(unsigned char** out, unsigned* w, unsigned* h,
                             const char* filename,
                             LodePNGColorType colortype, unsigned bitdepth);
unsigned lodepng_decode32_file(unsigned char** out, unsigned* w, unsigned* h,
                               const char* filename);
unsigned lodepng_decode24_file(unsigned char** out, unsigned* w, unsigned* h,
                               const char* filename);
unsigned lodepng_encode_memory(unsigned char** out, size_t* outsize,
                               const unsigned char* image, unsigned w, unsigned h,
                               LodePNGColorType colortype, unsigned bitdepth);
unsigned lodepng_encode32(unsigned char** out, size_t* outsize,
                          const unsigned char* image, unsigned w, unsigned h);
unsigned lodepng_encode24(unsigned char** out, size_t* outsize,
                          const unsigned char* image, unsigned w, unsigned h);
unsigned lodepng_encode_file(const char* filename,
                             const unsigned char* image, unsigned w, unsigned h,
                             LodePNGColorType colortype, unsigned bitdepth);
unsigned lodepng_encode32_file(const char* filename,
                               const unsigned char* image, unsigned w, unsigned h);
unsigned lodepng_encode24_file(const char* filename,
                               const unsigned char* image, unsigned w, unsigned h);
const char* lodepng_error_text(unsigned code);
typedef struct LodePNGDecompressSettings LodePNGDecompressSettings;

struct LodePNGDecompressSettings
{
  unsigned ignore_adler32;
  unsigned (*custom_zlib)(unsigned char**, size_t*,
                          const unsigned char*, size_t,
                          const LodePNGDecompressSettings*);
  unsigned (*custom_inflate)(unsigned char**, size_t*,
                             const unsigned char*, size_t,
                             const LodePNGDecompressSettings*);
  const void* custom_context;
};

extern const LodePNGDecompressSettings lodepng_default_decompress_settings;
void lodepng_decompress_settings_init(LodePNGDecompressSettings* settings);

typedef struct LodePNGCompressSettings LodePNGCompressSettings;
struct LodePNGCompressSettings
{
  unsigned btype;
  unsigned use_lz77;
  unsigned windowsize;
  unsigned minmatch;
  unsigned nicematch;
  unsigned lazymatching;
  unsigned (*custom_zlib)(unsigned char**, size_t*,
                          const unsigned char*, size_t,
                          const LodePNGCompressSettings*);
  unsigned (*custom_deflate)(unsigned char**, size_t*,
                             const unsigned char*, size_t,
                             const LodePNGCompressSettings*);
  const void* custom_context;
};

extern const LodePNGCompressSettings lodepng_default_compress_settings;
void lodepng_compress_settings_init(LodePNGCompressSettings* settings);

typedef struct LodePNGColorMode
{
  LodePNGColorType colortype;
  unsigned bitdepth;
  unsigned char* palette;
  size_t palettesize;
  unsigned key_defined;
  unsigned key_r;
  unsigned key_g;
  unsigned key_b;
} LodePNGColorMode;

void lodepng_color_mode_init(LodePNGColorMode* info);
void lodepng_color_mode_cleanup(LodePNGColorMode* info);
unsigned lodepng_color_mode_copy(LodePNGColorMode* dest, const LodePNGColorMode* source);
void lodepng_palette_clear(LodePNGColorMode* info);
unsigned lodepng_palette_add(LodePNGColorMode* info,
                             unsigned char r, unsigned char g, unsigned char b, unsigned char a);

unsigned lodepng_get_bpp(const LodePNGColorMode* info);
unsigned lodepng_get_channels(const LodePNGColorMode* info);
unsigned lodepng_is_greyscale_type(const LodePNGColorMode* info);
unsigned lodepng_is_alpha_type(const LodePNGColorMode* info);
unsigned lodepng_is_palette_type(const LodePNGColorMode* info);
unsigned lodepng_has_palette_alpha(const LodePNGColorMode* info);
unsigned lodepng_can_have_alpha(const LodePNGColorMode* info);
size_t lodepng_get_raw_size(unsigned w, unsigned h, const LodePNGColorMode* color);

typedef struct LodePNGTime
{
  unsigned year;
  unsigned month;
  unsigned day;
  unsigned hour;
  unsigned minute;
  unsigned second;
} LodePNGTime;

typedef struct LodePNGInfo
{
  unsigned compression_method;
  unsigned filter_method;
  unsigned interlace_method;
  LodePNGColorMode color;
  unsigned background_defined;
  unsigned background_r;
  unsigned background_g;
  unsigned background_b;
  size_t text_num;
  char** text_keys;
  char** text_strings;
  size_t itext_num;
  char** itext_keys;
  char** itext_langtags;
  char** itext_transkeys;
  char** itext_strings;
  unsigned time_defined;
  LodePNGTime time;
  unsigned phys_defined;
  unsigned phys_x;
  unsigned phys_y;
  unsigned phys_unit;
  unsigned char* unknown_chunks_data[3];
  size_t unknown_chunks_size[3];
} LodePNGInfo;

void lodepng_info_init(LodePNGInfo* info);
void lodepng_info_cleanup(LodePNGInfo* info);
unsigned lodepng_info_copy(LodePNGInfo* dest, const LodePNGInfo* source);
void lodepng_clear_text(LodePNGInfo* info);
unsigned lodepng_add_text(LodePNGInfo* info, const char* key, const char* str);
void lodepng_clear_itext(LodePNGInfo* info);
unsigned lodepng_add_itext(LodePNGInfo* info, const char* key, const char* langtag,
                           const char* transkey, const char* str);
unsigned lodepng_convert(unsigned char* out, const unsigned char* in,
                         LodePNGColorMode* mode_out, const LodePNGColorMode* mode_in,
                         unsigned w, unsigned h, unsigned fix_png);

typedef struct LodePNGDecoderSettings
{
  LodePNGDecompressSettings zlibsettings;
  unsigned ignore_crc;
  unsigned fix_png;
  unsigned color_convert;
  unsigned read_text_chunks;
  unsigned remember_unknown_chunks;
} LodePNGDecoderSettings;

void lodepng_decoder_settings_init(LodePNGDecoderSettings* settings);

typedef enum LodePNGFilterStrategy
{
  LFS_ZERO,
  LFS_MINSUM,
  LFS_ENTROPY,
  LFS_BRUTE_FORCE,
  LFS_PREDEFINED
} LodePNGFilterStrategy;

typedef enum LodePNGAutoConvert
{
  LAC_NO,
  LAC_ALPHA,
  LAC_AUTO,
  LAC_AUTO_NO_NIBBLES,
  LAC_AUTO_NO_PALETTE,
  LAC_AUTO_NO_NIBBLES_NO_PALETTE
} LodePNGAutoConvert;

unsigned lodepng_auto_choose_color(LodePNGColorMode* mode_out,
                                   const unsigned char* image, unsigned w, unsigned h,
                                   const LodePNGColorMode* mode_in,
                                   LodePNGAutoConvert auto_convert);

typedef struct LodePNGEncoderSettings
{
  LodePNGCompressSettings zlibsettings;
  LodePNGAutoConvert auto_convert;
  unsigned filter_palette_zero;
  LodePNGFilterStrategy filter_strategy;
  const unsigned char* predefined_filters;
  unsigned force_palette;
  unsigned add_id;
  unsigned text_compression;
} LodePNGEncoderSettings;

void lodepng_encoder_settings_init(LodePNGEncoderSettings* settings);

typedef struct LodePNGState
{
  LodePNGDecoderSettings decoder;
  LodePNGEncoderSettings encoder;
  LodePNGColorMode info_raw;
  LodePNGInfo info_png;
  unsigned error;
} LodePNGState;

void lodepng_state_init(LodePNGState* state);
void lodepng_state_cleanup(LodePNGState* state);
void lodepng_state_copy(LodePNGState* dest, const LodePNGState* source);

unsigned lodepng_decode(unsigned char** out, unsigned* w, unsigned* h,
                        LodePNGState* state,
                        const unsigned char* in, size_t insize);
unsigned lodepng_inspect(unsigned* w, unsigned* h,
                         LodePNGState* state,
                         const unsigned char* in, size_t insize);
unsigned lodepng_encode(unsigned char** out, size_t* outsize,
                        const unsigned char* image, unsigned w, unsigned h,
                        LodePNGState* state);

unsigned lodepng_chunk_length(const unsigned char* chunk);
void lodepng_chunk_type(char type[5], const unsigned char* chunk);
unsigned char lodepng_chunk_type_equals(const unsigned char* chunk, const char* type);
unsigned char lodepng_chunk_ancillary(const unsigned char* chunk);
unsigned char lodepng_chunk_private(const unsigned char* chunk);
unsigned char lodepng_chunk_safetocopy(const unsigned char* chunk);
unsigned char* lodepng_chunk_data(unsigned char* chunk);
const unsigned char* lodepng_chunk_data_const(const unsigned char* chunk);
unsigned lodepng_chunk_check_crc(const unsigned char* chunk);
void lodepng_chunk_generate_crc(unsigned char* chunk);
unsigned char* lodepng_chunk_next(unsigned char* chunk);
const unsigned char* lodepng_chunk_next_const(const unsigned char* chunk);
unsigned lodepng_chunk_append(unsigned char** out, size_t* outlength, const unsigned char* chunk);
unsigned lodepng_chunk_create(unsigned char** out, size_t* outlength, unsigned length,
                              const char* type, const unsigned char* data);

unsigned lodepng_crc32(const unsigned char* buf, size_t len);

unsigned lodepng_inflate(unsigned char** out, size_t* outsize,
                         const unsigned char* in, size_t insize,
                         const LodePNGDecompressSettings* settings);
unsigned lodepng_zlib_decompress(unsigned char** out, size_t* outsize,
                                 const unsigned char* in, size_t insize,
                                 const LodePNGDecompressSettings* settings);
unsigned lodepng_zlib_compress(unsigned char** out, size_t* outsize,
                               const unsigned char* in, size_t insize,
                               const LodePNGCompressSettings* settings);
unsigned lodepng_huffman_code_lengths(unsigned* lengths, const unsigned* frequencies,
                                      size_t numcodes, unsigned maxbitlen);
unsigned lodepng_deflate(unsigned char** out, size_t* outsize,
                         const unsigned char* in, size_t insize,
                         const LodePNGCompressSettings* settings);

unsigned lodepng_load_file(unsigned char** out, size_t* outsize, const char* filename);
unsigned lodepng_save_file(const unsigned char* buffer, size_t buffersize, const char* filename);
]])

return lib