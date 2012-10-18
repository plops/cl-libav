#include "/usr/local/include/libavformat/avformat.h"
#include "/usr/local/include/libavcodec/avcodec.h"
#include "/usr/local/include/libswscale/swscale.h"
#include <stdlib.h>
#include <pthread.h>

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

static int lockmgr(void**mutex,enum AVLockOp op)
{
  pthread_mutex_t **m = (pthread_mutex_t**) mutex;
  switch(op){
  case AV_LOCK_CREATE:
    *m = (pthread_mutex_t*) malloc(sizeof(pthread_mutex_t));
    pthread_mutex_init(*m,NULL);
    break;
  case AV_LOCK_OBTAIN:
    pthread_mutex_lock(*m);
    break;
  case AV_LOCK_RELEASE:
    pthread_mutex_unlock(*m);
    break;
  case AV_LOCK_DESTROY:
    pthread_mutex_destroy(*m);
    free(*m);
    break;
  }
  return 0;
}

void vid_libinit()
{
  static pthread_mutex_t m=PTHREAD_MUTEX_INITIALIZER;
  pthread_mutex_lock(&m);
  av_lockmgr_register(lockmgr);
  avcodec_register_all();
  av_register_all();
  av_log_set_level(AV_LOG_QUIET);
  pthread_mutex_unlock(&m);
}

int vid_init(Vid*v,const char*fn)
{
  static pthread_mutex_t m=PTHREAD_MUTEX_INITIALIZER;
  pthread_mutex_lock(&m);

  if(avformat_open_input(&(v->ic),fn,NULL,NULL)<0)
    return -1;
  if(avformat_find_stream_info(v->ic,NULL)<0)
    return -2;

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
  pthread_mutex_unlock(&m);
  return 0;
}


void vid_close(Vid*v)
{
  static pthread_mutex_t m=PTHREAD_MUTEX_INITIALIZER;
  pthread_mutex_lock(&m);

  sws_freeContext(v->sc);
  av_free(v->frame);
  avpicture_free(&(v->pict));
  v->ic->streams[v->vstream]->discard = AVDISCARD_ALL;
  avcodec_close(v->avctx);

  avformat_close_input(&(v->ic));
  pthread_mutex_unlock(&m);
}

int vid_decode_frame(Vid*v)
{
  static pthread_mutex_t m=PTHREAD_MUTEX_INITIALIZER;
  pthread_mutex_lock(&m);
  
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
  pthread_mutex_unlock(&m);
  return 1;
}

int main()
{
  
  const char *fn=
    "/home/martin/Downloads2/XDC2012_-_OpenGL_Future-LesAb4sTXgA.flv";

  
  
  vid_libinit();
  Vid*v=vid_alloc();
  vid_init(v,fn);
  Vid*v2=vid_alloc();
  //vid_init(v2,"/home/martin/Downloads2/RC_helicopter_upside_down_head_touch-1Lg6wASg76o.mp4");
    
  while(vid_decode_frame(v)){
    static int i=0;
    printf("%d\n",i++);
  }

  vid_close(v);

  return 0;
}
