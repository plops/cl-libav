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

int vid_get_width(Vid*v){ return v->avctx->width;}
int vid_get_height(Vid*v){ return v->avctx->height;}
uint8_t* vid_get_data(Vid*v,int i){ return v->pict.data[i];}
int vid_get_linesize(Vid*v,int i){return v->pict.linesize[i];}

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

int vid_decode_frame(Vid*v)
{
  int finished=-1;
  while(finished<=0){
    if(av_read_frame(v->ic,&(v->pkt))<0)
      return 0;
    if(v->pkt.stream_index == v->vstream)
      avcodec_decode_video2(v->avctx,v->frame,&finished,&(v->pkt));
    if(finished>0)
      sws_scale(v->sc, (const uint8_t **) v->frame->data, v->frame->linesize,
		0, v->frame->height, v->pict.data, v->pict.linesize);
    av_free_packet(&(v->pkt));
  }
  return 1;
}

int main()
{
  
  const char *fn=
    "/home/martin/Downloads2/XDC2012_-_OpenGL_Future-LesAb4sTXgA.flv";
  Vid*v=vid_alloc();
  vid_init(v,fn);
    
  while(vid_decode_frame(v)){
    static int i=0;
    printf("%d\n",i++);
  }

  vid_close(v);

  return 0;
}
