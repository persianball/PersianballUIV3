import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../models/VideoDetail.dart';

class VideoPlayerPage extends StatefulWidget {
  final VideoDetail? videoDetail;
  const VideoPlayerPage({super.key, required this.videoDetail});

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {


  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;




  @override
  void initState() {
    super.initState();

    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoDetail!.hlsUrl),
    );

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: 16/9,

    );
  }

  @override
  void dispose() {

    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();

  }

  List<String> urls=[
    // "https://ahmadrezafs.arvanvod.ir/Kn0Y4LYzDW/aY3RqDKVLW/h_,144_200,240_400,k.mp4.list/master.m3u8",
    "https://ahmadrezafs.arvanvod.ir/Kn0Y4LYzDW/aY3RqDKVLW/h_,144_200,240_400,k.mp4.list/master.m3u8",
    "https://ahmadrezafs.arvanvod.ir/Kn0Y4LYzDW/aKEvOmVJbo/h_,144_200,240_400,360_800,480_1500,720_2500,1080_4500,k.mp4.list/master.m3u8",
    "https://ahmadrezafs.arvanvod.ir/Kn0Y4LYzDW/3VJN5kzn5p/h_,144_200,240_400,360_800,480_1500,720_2500,1080_4500,k.mp4.list/master.m3u8"
  ];



  @override
  Widget build(BuildContext context) {
    if(widget.videoDetail!=null){

        return Builder(
            builder: (context) {
              _videoPlayerController.dispose();
              _chewieController.dispose();

              _videoPlayerController = VideoPlayerController.networkUrl(
                  Uri.parse(widget.videoDetail!.hlsUrl)
              );

              _chewieController = ChewieController(
                videoPlayerController: _videoPlayerController,
                aspectRatio: 16/9,
                autoPlay: true,

              );
              //widget.item_scroll_controller.scrollTo(index: videoIndex, duration: const Duration(milliseconds: 100));


              return AspectRatio(
                aspectRatio: 16/9,
                child: Chewie(controller: _chewieController),
              );
              // return YoYoPlayer(
              //   onFullScreen: (fullscreen)=>{
              //     //TODO:show and hide app bar in fullscreen mode
              //   },
              //   onVideoInitCompleted:(controller){
              //
              //     _videoPlayerController = controller;
              //   },
              //   aspectRatio: 16 / 9,
              //   // Url (Video streaming links)
              //   // 'https://dsqqu7oxq6o1v.cloudfront.net/preview-9650dW8x3YLoZ8.webm',
              //   // "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
              //   // "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
              //   url:urls[videoIndex%urls.length],
              //   videoStyle: const VideoStyle(
              //     qualityStyle: TextStyle(
              //       fontSize: 16.0,
              //       fontWeight: FontWeight.w500,
              //       color: Colors.white,
              //     ),
              //     forwardAndBackwardBtSize: 30.0,
              //     playButtonIconSize: 40.0,
              //     playIcon: Icon(
              //       Icons.play_arrow,
              //       size: 40.0,
              //       color: Colors.white,
              //     ),
              //     pauseIcon: Icon(
              //       Icons.pause,
              //       size: 40.0,
              //       color: Colors.white,
              //     ),
              //     videoQualityPadding: EdgeInsets.all(5.0),
              //   ),
              //   videoLoadingStyle: const VideoLoadingStyle(
              //     loading: Center(
              //       child: Row(
              //         children: [
              //           CircularProgressIndicator(),
              //           Text(
              //             "Loading video",
              //             style: TextStyle(color: Colors.white, fontSize: 12),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              //   allowCacheFile: true,
              //   onCacheFileCompleted: (files) {
              //     print('Cached file length ::: ${files?.length}');
              //
              //     if (files != null && files.isNotEmpty) {
              //       for (var file in files) {
              //         print('File path ::: ${file.path}');
              //       }
              //     }
              //   },
              // );
            }
        );


    }
    else{
      return Center(
        child: Text(
          "ویدیو در دسترس نمی‌باشد.",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,
            color: Colors.white),
        ),
      );
    }

  }
}
