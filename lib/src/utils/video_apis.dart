import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/vimeo_models.dart';

String podErrorString(String val) {
  return '*\n------error------\n\n$val\n\n------end------\n*';
}

class VideoApis {
  static Future<List<VideoQalityUrls>?> getVimeoVideoQualityUrls(
    String videoId,
  ) async {
    try {
      log('بسم الله الرحمن الرحيم');
      final response = await http.get(
        Uri.parse('https://player.vimeo.com/video/$videoId/config'),
        headers: {
          'VIMEO_CLIENT': '561d8e43675bf6aeeebba80cff792d98ac7fba26',
          'VIMEO_SECRET':
              'LFLaegKc7RWzqO4gU8WZ68c42KJg8LNGsJeJ4VBnypR6CgNJ6uijvvBdz1cGKvvvyAkV1uta2ftw9jPE+Q4cZtq2EOyuhoaqQb2kB0L0z0PTpKK8fHgY7IGYMCQe5A2j',
          'VIMEO_ACCESS': '4bddd0cb20c5b347887e65b90ddae7da',
        },
      );
      final jsonData =
          jsonDecode(response.body)['request']['files']['progressive'];

      final bool progressiveListIsEmpty = (jsonData as List).isEmpty;

      if (progressiveListIsEmpty) {
        log('calling new-api => this video doesn\'t have progressive from the old-api.');

        final response = await http.get(
          Uri.parse(
              'https://academytest2.troylab.org/api/get_video_data/$videoId'),
        );
        final jsonData = List.from(jsonDecode(response.body)['files']);

        final newList = jsonData.map(
          (json) {
            if (json['height'] != null) {
              return VideoQalityUrls(
                quality: json['height'],
                url: json['link'],
              );
            }
          },
        ).toList();

        if (newList.contains(null)) {
          newList.remove(null);
        }

        return List<VideoQalityUrls>.from(newList);
      } else {
        log('calling old-api => this video has progressive already.');
        return List.generate(
          jsonData.length,
          (index) => VideoQalityUrls(
            quality: int.parse(
              (jsonData[index]['quality'] as String?)?.split('p').first ?? '0',
            ),
            url: jsonData[index]['url'],
          ),
        );
      }
    } catch (error) {
      if (error.toString().contains('XMLHttpRequest')) {
        log(
          podErrorString(
            '(INFO) To play vimeo video in WEB, Please enable CORS in your browser',
          ),
        );
      }
      debugPrint('===== VIMEO API ERROR: $error ==========');
      rethrow;
    }
    return null;
  }

  static Future<List<VideoQalityUrls>?> getYoutubeVideoQualityUrls(
    String youtubeIdOrUrl,
    bool live,
  ) async {
    try {
      final yt = YoutubeExplode();
      final urls = <VideoQalityUrls>[];
      if (live) {
        final url = await yt.videos.streamsClient.getHttpLiveStreamUrl(
          VideoId(youtubeIdOrUrl),
        );
        urls.add(
          VideoQalityUrls(
            quality: 360,
            url: url,
          ),
        );
      } else {
        final manifest =
            await yt.videos.streamsClient.getManifest(youtubeIdOrUrl);
        urls.addAll(
          manifest.muxed.map(
            (element) => VideoQalityUrls(
              quality: int.parse(element.qualityLabel.split('p')[0]),
              url: element.url.toString(),
            ),
          ),
        );
      }
      // Close the YoutubeExplode's http client.
      yt.close();
      return urls;
    } catch (error) {
      if (error.toString().contains('XMLHttpRequest')) {
        log(
          podErrorString(
            '(INFO) To play youtube video in WEB, Please enable CORS in your browser',
          ),
        );
      }
      debugPrint('===== YOUTUBE API ERROR: $error ==========');
      rethrow;
    }
  }
}
