import 'package:brainrotvision_flutter/providers/app_state.dart';
import 'package:brainrotvision_flutter/screens/home_screen.dart';
import 'package:brainrotvision_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const BrainrotVisionApp());
}

class BrainrotVisionApp extends StatelessWidget {
  const BrainrotVisionApp({super.key, this.apiService});

  final ApiService? apiService;

  @override
  Widget build(BuildContext context) {
    final palette = _AppPalette();
    return ChangeNotifierProvider(
      create: (_) => AppState(api: apiService ?? ApiService.fromEnvironment()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BrainrotVision',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: palette.rust,
            brightness: Brightness.light,
            primary: palette.ink,
            secondary: palette.rust,
            surface: palette.paper,
          ),
          scaffoldBackgroundColor: palette.paper,
          textTheme: GoogleFonts.spaceGroteskTextTheme(),
          cardTheme: CardThemeData(
            color: Colors.white.withValues(alpha: 0.92),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: palette.ink.withValues(alpha: 0.08)),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class _AppPalette {
  final Color paper = const Color(0xFFF5EBDD);
  final Color ink = const Color(0xFF17322D);
  final Color rust = const Color(0xFFC8623B);
}
