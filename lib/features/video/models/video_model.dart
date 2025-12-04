import 'package:flutter/foundation.dart';

class VideoCategory {
  final int id;
  final String name;
  final String description;
  final String icon;
  final int videoCount;

  const VideoCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.videoCount,
  });

  factory VideoCategory.fromJson(Map<String, dynamic> json) {
    return VideoCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      videoCount: json['videoCount'] ?? 0,
    );
  }
}

class PreventionVideo {
  final int id;
  final String title;
  final String description;
  final String youtubeId;
  final String youtubeUrl;
  final String thumbnailUrl;
  final String duration;
  final int viewCount;
  final int categoryId;

  const PreventionVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeId,
    required this.youtubeUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.viewCount,
    required this.categoryId,
  });

  factory PreventionVideo.fromJson(Map<String, dynamic> json) {
    return PreventionVideo(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      youtubeId: json['youtubeId'],
      youtubeUrl: json['youtubeUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'] ?? '',
      viewCount: json['viewCount'] ?? 0,
      categoryId: json['categoryId'],
    );
  }
}
