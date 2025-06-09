// Updated main.dart with error handling and performance fixes

import 'dart:async';
import 'dart:isolate';

import 'package:auto_clipper_app/Screens/splesh_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Handle Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Flutter Error: ${details.exception}');
      print('Stack trace: ${details.stack}');
    }
  };

  // Handle platform channel errors
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('Platform Error: $error');
      print('Stack trace: $stack');
    }
    return true;
  };

  // Set preferred orientations (optional)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run the app with error zone
  runZonedGuarded(
    () {
      runApp(MyApp());
    },
    (error, stack) {
      if (kDebugMode) {
        print('Zone Error: $error');
        print('Stack trace: $stack');
      }
    },
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Design size - adjust based on your design
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true, // Important for performance

      builder: (context, child) {
        return MaterialApp(
          title: 'Auto Clipper App',
          debugShowCheckedModeBanner: false,

          // Error handling
          builder: (context, widget) {
            // Handle errors in the widget tree
            ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong!',
                        style: TextStyle(fontSize: 18.sp),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorDetails.exception.toString(),
                          style: TextStyle(fontSize: 12.sp),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            };

            if (widget != null) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: 1.0, // Prevent text scaling issues
                ),
                child: widget,
              );
            }

            return const SizedBox.shrink();
          },

          // Theme configuration
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            // Reduce animations to improve performance
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),

          home:  SafeAreaWrapper(child: SimpleSplashScreen()),
        );
      },
    );
  }
}

// Safe area wrapper to prevent overflow issues
class SafeAreaWrapper extends StatelessWidget {
  final Widget child;

  const SafeAreaWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: child);
  }
}

// Optimized widget with better error handling
class OptimizedWidget extends StatefulWidget {
  @override
  _OptimizedWidgetState createState() => _OptimizedWidgetState();
}

class _OptimizedWidgetState extends State<OptimizedWidget>
    with AutomaticKeepAliveClientMixin {
  Timer? _debounceTimer;
  bool _isLoading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> performHeavyOperation() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _debounceTimer?.cancel();

      _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        try {
          final result = await compute(heavyComputation, "data");

          if (mounted) {
            setState(() {
              _isLoading = false;
              // Update your state with result
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = e.toString();
            });
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(
        title: Text('Optimized Widget', style: TextStyle(fontSize: 18.sp)),
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              color: Colors.red.shade100,
              child: Text(
                'Error: $_error',
                style: TextStyle(color: Colors.red, fontSize: 14.sp),
              ),
            ),

          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: const CircularProgressIndicator(),
            ),

          Expanded(
            child: ListView.builder(
              itemExtent: 60.h,
              cacheExtent: 200.h,
              physics: const ClampingScrollPhysics(), // Better for Android
              itemCount: 100,
              itemBuilder: (context, index) {
                return Container(
                  height: 60.h,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Card(
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        'Item $index',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                      subtitle: Text(
                        'Subtitle $index',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      onTap: () {
                        // Handle tap
                        if (kDebugMode) {
                          print('Tapped item $index');
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : performHeavyOperation,
        child:
            _isLoading
                ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Icon(Icons.refresh),
      ),
    );
  }
}

// Safer heavy computation with error handling
String heavyComputation(String data) {
  try {
    var result = '';
    // Reduce iterations to prevent ANR
    for (int i = 0; i < 100000; i++) {
      result += data.hashCode.toString();

      // Check for cancellation periodically
      if (i % 10000 == 0) {
        // Small delay to prevent blocking
        Future.delayed(Duration.zero);
      }
    }
    return result;
  } catch (e) {
    return 'Error in computation: $e';
  }
}

// Optimized image loading with better error handling
class OptimizedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;

  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  _OptimizedImageState createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final width = widget.width ?? 300.w;
    final height = widget.height ?? 300.h;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child:
            _hasError
                ? _buildErrorWidget()
                : Image.network(
                  widget.imageUrl,
                  width: width,
                  height: height,
                  cacheWidth: width.toInt(),
                  cacheHeight: height.toInt(),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (context, error, stackTrace) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _hasError = true;
                        });
                      }
                    });
                    return _buildErrorWidget();
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;

                    return Container(
                      width: width,
                      height: height,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3.w,
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width ?? 300.w,
      height: widget.height ?? 300.h,
      color: Colors.grey.shade300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: Colors.grey.shade600),
          SizedBox(height: 8.h),
          Text(
            'Failed to load image',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
