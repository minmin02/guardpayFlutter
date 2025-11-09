import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:guardpayfront/features/video/services/video_service.dart';
import 'package:guardpayfront/features/video/models/video_model.dart';

class VideoPlayerScreen extends StatefulWidget {
  final int videoId;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final VideoService _videoService = VideoService();
  late Future<PreventionVideo> _videoFuture;

  @override
  void initState() {
    super.initState();
    _videoFuture = _videoService.fetchVideoDetail(widget.videoId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EC),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: FutureBuilder<PreventionVideo>(
        future: _videoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('영상을 불러올 수 없습니다.\n${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('영상 정보가 없습니다.'));
          }

          final video = snapshot.data!;

          // ✅ 여기서 controller 생성
          final controller = YoutubePlayerController(
            initialVideoId: video.youtubeId,
            flags: const YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
            ),
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ YouTube 플레이어
                YoutubePlayer(
                  controller: controller,
                  showVideoProgressIndicator: true,
                ),

                // 영상 정보
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '조회수 ${video.viewCount} • ${video.duration}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        video.description,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}