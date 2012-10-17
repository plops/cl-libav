#include "/usr/local/include/libavformat/avformat.h"
#include "/usr/local/include/libavcodec/avcodec.h"
#include "/usr/local/include/libswscale/swscale.h"

int main()
{
  avcodec_register_all();
  av_register_all();

  AVFormatContext *ic;
  const char *fn=
    "/home/martin/Downloads2/XDC2012_-_OpenGL_Future-LesAb4sTXgA.flv";
  
  avformat_open_input(&ic,fn,NULL,NULL);

  avformat_find_stream_info(ic,NULL);

  int vstream=av_find_best_stream(ic,AVMEDIA_TYPE_VIDEO,-1,-1,NULL,0);

  //av_dump_format(ic,0,fn,0);
  
  AVCodecContext *avctx=ic->streams[vstream]->codec;
  AVCodec *codec = avcodec_find_decoder(avctx->codec_id);
  //  avctx->flags |= CODEC_FLAG_TRUNCATED;
  // avctx->flags2 |= CODEC_FLAG2_FAST;
  
  avcodec_open2(avctx,codec,NULL);

  AVFrame *frame=avcodec_alloc_frame();
  AVPacket pkt;
  int eof=0;


  int w=avctx->width,h=avctx->height,fmt=PIX_FMT_RGB32; 
  struct SwsContext *sc;
  static int sws_flags = SWS_BILINEAR;

  sc = sws_getCachedContext(0,
			    w,h,avctx->pix_fmt,
			    w,h,fmt,
			    sws_flags, NULL, NULL, NULL);

  AVPicture pict;
  avpicture_alloc(&pict,fmt,w,h);
  
  while(!eof){
    eof=av_read_frame(ic,&pkt)<0?1:0;
    int finished=-1;
    if(pkt.stream_index == vstream)
      avcodec_decode_video2(avctx,frame,&finished,&pkt);
    if(finished>0){
      printf("%08ld %dx%d %d %d %d\n",
	     frame->pkt_pts,
	     frame->width,frame->height,
	     frame->linesize[0],
	     frame->linesize[1],
	     frame->linesize[2]);
      
      sws_scale(sc, (const uint8_t **) frame->data, frame->linesize,
		0, frame->height, pict.data, pict.linesize);
    }
    av_free_packet(&pkt);
  }

  sws_freeContext(sc);
  av_free(frame);
  avpicture_free(&pict);
  ic->streams[vstream]->discard = AVDISCARD_ALL;
  avcodec_close(avctx);

  avformat_close_input(&ic);
  


  return 0;
}
