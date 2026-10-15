import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:persian_ball/constant/app_color.dart';

// Simple media model to support both images and videos with thumbnails
enum MediaType { image, video }

class MediaItem {
  final MediaType type;
  final String url; // image url or video url
  final String thumbnailUrl; // for image can be same as url; for video provided by backend

  const MediaItem({
    required this.type,
    required this.url,
    required this.thumbnailUrl,
  });

  // Convenience constructors
  factory MediaItem.image({required String url}) =>
      MediaItem(type: MediaType.image, url: url, thumbnailUrl: url);

  factory MediaItem.video({required String url, required String thumbnailUrl}) =>
      MediaItem(type: MediaType.video, url: url, thumbnailUrl: thumbnailUrl);

  bool get isVideo => type == MediaType.video;
  bool get isImage => type == MediaType.image;
}

class CarouselImageViewer extends StatefulWidget {
  // Backward compatibility: existing callers can still pass imageUrls
  final List<String>? imageUrls;

  // New: pass mixed media items (images + videos)
  final List<MediaItem>? mediaItems;

  final double mainImageHeight;
  final double thumbnailSize;
  final double thumbnailSpacing;

  /// اسلایدی که در ابتدا نمایش داده می‌شود
  final int initialIndex;

  /// با تغییر اسلاید صدا زده می‌شود
  final ValueChanged<int>? onIndexChanged;

  const CarouselImageViewer({
    Key? key,
    this.imageUrls,
    this.mediaItems,
    this.mainImageHeight = 300.0,
    this.thumbnailSize = 80.0,
    this.thumbnailSpacing = 8.0,
    this.initialIndex = 0,
    this.onIndexChanged,
  })  : assert(
            (mediaItems != null && mediaItems.length>0) ||
                (imageUrls != null && imageUrls.length>0),
            'Provide either mediaItems or imageUrls'),
        super(key: key);

  @override
  State<CarouselImageViewer> createState() => _CarouselImageViewerState();
}

class _CarouselImageViewerState extends State<CarouselImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  // Video controllers cached per index
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, ChewieController> _chewieControllers = {};
  final Set<int> _initializing = {}; // prevent duplicate inits

  List<MediaItem> get _items => widget.mediaItems ??
      (widget.imageUrls ?? []).map((e) => MediaItem.image(url: e)).toList();

  @override
  void initState() {
    super.initState();
    // اگر ایندکس ذخیره‌شده از محتوای فعلی بزرگ‌تر باشد، به آخرین اسلاید محدود می‌شود
    _currentIndex = widget.initialIndex.clamp(0, _items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _playVideo(_currentIndex);
  }

  @override
  void dispose() {
    // Dispose all video controllers
    for (final c in _chewieControllers.values) {
      c.dispose();
    }
    for (final v in _videoControllers.values) {
      v.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onThumbnailTap(int index) {
    // Pause current video if needed
    _pauseVideoAt(_currentIndex);

    setState(() {
      _currentIndex = index;
    });
    widget.onIndexChanged?.call(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    // Pause previous video when leaving page
    _pauseVideoAt(_currentIndex);
    setState(() {
      _currentIndex = index;
    });
    widget.onIndexChanged?.call(index);
  }

  void _pauseVideoAt(int index) {
    final controller = _videoControllers[index];
    if (controller != null && controller.value.isPlaying) {
      controller.pause();
    }
  }

  Future<void> _playVideo(int index) async {
    if (_chewieControllers[index] != null &&
        _videoControllers[index]?.value.isInitialized == true) {
      // Already initialized; just ensure playing
      _videoControllers[index]!.play();
      setState(() {});
      return;
    }

    if (_initializing.contains(index)) return; // already starting
    _initializing.add(index);

    try {
      final item = _items[index];
      final videoController =
          VideoPlayerController.networkUrl(Uri.parse(item.url));
      await videoController.initialize();
      final chewie = ChewieController(
        videoPlayerController: videoController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColor.goldEnd,
          handleColor: AppColor.goldEnd,
          backgroundColor: Colors.black26,
          bufferedColor: Colors.white54,
        ),
      );
      _videoControllers[index] = videoController;
      _chewieControllers[index] = chewie;
      if (mounted) setState(() {});
    } catch (_) {
      // ignore errors; UI will continue to show thumbnail/error
    } finally {
      _initializing.remove(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main media viewer with overlaid thumbnails
        Container(
          height: widget.mainImageHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Main pages
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];

                    if (item.isImage) {
                      // Image page
                      return Image.network(
                        item.url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.error_outline,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      );
                    } else {
                      // Video page: show player if initialized; otherwise show thumbnail with play button
                      final isReady = _videoControllers[index]?.value.isInitialized == true;
                      final chewie = _chewieControllers[index];

                      if (isReady && chewie != null) {
                        return Chewie(controller: chewie);
                      }

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Video thumbnail from backend
                          Image.network(
                            item.thumbnailUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.error_outline,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                          // Dark gradient bottom for readability (optional)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: 80,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black54,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Center play button
                          Center(
                            child: GestureDetector(
                              onTap: () => _playVideo(index),
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 42,
                                ),
                              ),
                            ),
                          ),
                          if (_initializing.contains(index))
                            const Center(
                              child: SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      );
                    }
                  },
                ),

                // Overlaid thumbnails
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: SizedBox(
                    height: widget.thumbnailSize,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentIndex;
                        final item = _items[index];
                        return GestureDetector(
                          onTap: () => _onThumbnailTap(index),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: index == _items.length - 1
                                  ? 0
                                  : widget.thumbnailSpacing,
                            ),
                            width: widget.thumbnailSize,
                            height: widget.thumbnailSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColor.goldEnd
                                    : Colors.white.withOpacity(0.8),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    item.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.error_outline,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                  if (item.isVideo)
                                    Center(
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _items.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentIndex
                    ? AppColor.goldEnd
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CarouselExampleScreen extends StatelessWidget {
  const CarouselExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample media: mix of images and one video with backend-provided thumbnail
    final List<MediaItem> sampleMedia = [
      MediaItem.image(url: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800'),
      MediaItem.image(url: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=800'),
      MediaItem.video(
        url:
            'https://flutter.github.io/assets-for-api-docs/assets/bee.mp4', // sample video
        thumbnailUrl:
            'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=800',
      ),
      MediaItem.image(url: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800'),
      MediaItem.image(url: 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=800'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carousel Image/Video Viewer'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Gallery',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CarouselImageViewer(
              mediaItems: sampleMedia,
              mainImageHeight: 250,
              thumbnailSize: 70,
              thumbnailSpacing: 12,
            ),
            const SizedBox(height: 24),
            const Text(
              'Features:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Swipe between images/videos\n'
              '• Tap thumbnail to jump\n'
              '• For videos: shows backend thumbnail and inline player (Chewie)\n'
              '• Loading states and error handling\n'
              '• Customizable sizes and spacing',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}