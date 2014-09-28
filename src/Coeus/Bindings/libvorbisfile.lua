local Coeus = ...
local ffi = require("ffi")
local libvorbisfile

if (ffi.os == "Windows") then
	libvorbisfile = ffi.load(Coeus.BinDir .. "libvorbisfile")
else
	libvorbisfile = ffi.load("libvorbisfile")
end

Coeus:Load("Bindings.libvorbis")
Coeus:Load("Bindings.stdio_")

--vorbisfile.h
ffi.cdef([[
typedef struct {
	size_t (*read_func)  (void *ptr, size_t size, size_t nmemb, void *datasource);
	int    (*seek_func)  (void *datasource, ogg_int64_t offset, int whence);
	int    (*close_func) (void *datasource);
	long   (*tell_func)  (void *datasource);
} ov_callbacks;

enum {
	NOTOPEN = 0,
	PARTOPEN = 1,
	OPENED = 2,
	STREAMSET = 3,
	INITSET = 4
};

typedef struct OggVorbis_File {
	void            *datasource;
	int              seekable;
	ogg_int64_t      offset;
	ogg_int64_t      end;
	ogg_sync_state   oy;

	int              links;
	ogg_int64_t     *offsets;
	ogg_int64_t     *dataoffsets;
	long            *serialnos;
	ogg_int64_t     *pcmlengths;

	vorbis_info     *vi;
	vorbis_comment  *vc;

	ogg_int64_t      pcm_offset;
	int              ready_state;
	long             current_serialno;
	int              current_link;

	double           bittrack;
	double           samptrack;

	ogg_stream_state os;
	vorbis_dsp_state vd;
	vorbis_block     vb;

	ov_callbacks callbacks;
} OggVorbis_File;


extern int ov_clear(OggVorbis_File *vf);
extern int ov_fopen(const char *path,OggVorbis_File *vf);
extern int ov_open(FILE *f,OggVorbis_File *vf,const char *initial,long ibytes);
extern int ov_open_callbacks(void *datasource, OggVorbis_File *vf,
                const char *initial, long ibytes, ov_callbacks callbacks);

extern int ov_test(FILE *f,OggVorbis_File *vf,const char *initial,long ibytes);
extern int ov_test_callbacks(void *datasource, OggVorbis_File *vf,
                const char *initial, long ibytes, ov_callbacks callbacks);
extern int ov_test_open(OggVorbis_File *vf);

extern long ov_bitrate(OggVorbis_File *vf,int i);
extern long ov_bitrate_instant(OggVorbis_File *vf);
extern long ov_streams(OggVorbis_File *vf);
extern long ov_seekable(OggVorbis_File *vf);
extern long ov_serialnumber(OggVorbis_File *vf,int i);

extern ogg_int64_t ov_raw_total(OggVorbis_File *vf,int i);
extern ogg_int64_t ov_pcm_total(OggVorbis_File *vf,int i);
extern double ov_time_total(OggVorbis_File *vf,int i);

extern int ov_raw_seek(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_pcm_seek(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_pcm_seek_page(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_time_seek(OggVorbis_File *vf,double pos);
extern int ov_time_seek_page(OggVorbis_File *vf,double pos);

extern int ov_raw_seek_lap(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_pcm_seek_lap(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_pcm_seek_page_lap(OggVorbis_File *vf,ogg_int64_t pos);
extern int ov_time_seek_lap(OggVorbis_File *vf,double pos);
extern int ov_time_seek_page_lap(OggVorbis_File *vf,double pos);

extern ogg_int64_t ov_raw_tell(OggVorbis_File *vf);
extern ogg_int64_t ov_pcm_tell(OggVorbis_File *vf);
extern double ov_time_tell(OggVorbis_File *vf);

extern vorbis_info *ov_info(OggVorbis_File *vf,int link);
extern vorbis_comment *ov_comment(OggVorbis_File *vf,int link);

extern long ov_read_float(OggVorbis_File *vf,float ***pcm_channels,int samples,
                          int *bitstream);
extern long ov_read_filter(OggVorbis_File *vf,char *buffer,int length,
                          int bigendianp,int word,int sgned,int *bitstream,
                          void (*filter)(float **pcm,long channels,long samples,void *filter_param),void *filter_param);
extern long ov_read(OggVorbis_File *vf,char *buffer,int length,
                    int bigendianp,int word,int sgned,int *bitstream);
extern int ov_crosslap(OggVorbis_File *vf1,OggVorbis_File *vf2);

extern int ov_halfrate(OggVorbis_File *vf,int flag);
extern int ov_halfrate_p(OggVorbis_File *vf);
]])

return libvorbisfile