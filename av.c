#include "/usr/local/include/libavformat/avformat.h"
#include "/usr/local/include/libavcodec/avcodec.h"
#include "/usr/local/include/libswscale/swscale.h"
#include <stdlib.h>


typedef struct Vid Vid;
struct Vid {
  AVFormatContext *ic;
  int vstream;
  AVCodecContext *avctx;
  AVCodec *codec;
  AVFrame *frame;
  AVPacket pkt;
  int fmt;
  struct SwsContext *sc;
  int sws_flags;
  AVPicture pict;
};

Vid*vid_alloc()
{
  return (Vid*)malloc(sizeof(Vid));
}

void vid_init(Vid*v,const char*fn)
{
  avcodec_register_all();
  av_register_all();

  avformat_open_input(&(v->ic),fn,NULL,NULL);
  avformat_find_stream_info(v->ic,NULL);

  v->vstream=av_find_best_stream(v->ic,AVMEDIA_TYPE_VIDEO,-1,-1,NULL,0);
  v->avctx=v->ic->streams[v->vstream]->codec;
  v->codec = avcodec_find_decoder(v->avctx->codec_id);
  avcodec_open2(v->avctx,v->codec,NULL);

  v->frame=avcodec_alloc_frame();
    
  int w=v->avctx->width,h=v->avctx->height;
  v->fmt=PIX_FMT_RGB32; 
  v->sws_flags = SWS_BILINEAR;
  
  v->sc = sws_getCachedContext(0,
			    w,h,v->avctx->pix_fmt,
			    w,h,v->fmt,
			    v->sws_flags, NULL, NULL, NULL);
  avpicture_alloc(&(v->pict),v->fmt,w,h);
}


void vid_close(Vid*v)
{
  sws_freeContext(v->sc);
  av_free(v->frame);
  avpicture_free(&(v->pict));
  v->ic->streams[v->vstream]->discard = AVDISCARD_ALL;
  avcodec_close(v->avctx);

  avformat_close_input(&(v->ic));
}

int main()
{
  
  const char *fn=
    "/home/martin/Downloads2/XDC2012_-_OpenGL_Future-LesAb4sTXgA.flv";
  Vid*v=vid_alloc();
  vid_init(v,fn);
  
  int eof=0;
  
  while(!eof){
    eof=av_read_frame(v->ic,&(v->pkt))<0?1:0;
    int finished=-1;
    if(v->pkt.stream_index == v->vstream)
      avcodec_decode_video2(v->avctx,v->frame,&finished,&(v->pkt));
    if(finished>0){
      sws_scale(v->sc, (const uint8_t **) v->frame->data, v->frame->linesize,
		0, v->frame->height, v->pict.data, v->pict.linesize);
    }
    av_free_packet(&(v->pkt));
  }

  vid_close(v);

  return 0;
}
