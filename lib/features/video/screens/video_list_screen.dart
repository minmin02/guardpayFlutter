import 'package:flutter/material.dart';
import 'package:guardpayfront/features/video/models/video_model.dart';
import 'package:guardpayfront/features/video/services/video_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoListScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const VideoListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final VideoService _videoService = VideoService();
  late Future<List<PreventionVideo>> _videos;

  @override
  void initState() {
    super.initState();
    _videos = _videoService.fetchVideosByCategory(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EC),
      appBar: AppBar(
        title: Text(
          '${widget.categoryName} 예방 영상',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: FutureBuilder<List<PreventionVideo>>(
        future: _videos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('영상 데이터를 불러오지 못했습니다.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('등록된 영상이 없습니다.'));
          }

          final videos = snapshot.data!;
          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/videoPlayer',
                    arguments: {'videoId': video.id, 'title': video.title},
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: video.thumbnailUrl,
                          width: 130,
                          height: 80,
                          fit: BoxFit.cover,
                          errorWidget: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                video.duration,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '조회수 ${video.viewCount}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Icon(Icons.play_circle_fill, color: Colors.redAccent),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
