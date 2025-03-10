import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_music/Models/Track.dart';
import 'package:vibe_music/data/home1.dart';
import 'package:vibe_music/providers/AudioQualityprovider.dart';
import 'package:vibe_music/providers/LanguageProvider.dart';
import 'package:vibe_music/providers/MusicPlayer.dart';
import 'package:vibe_music/providers/ThemeProvider.dart';
import 'package:vibe_music/screens/MainScreen.dart';
import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: false,
  );
  await Hive.initFlutter();
  Hive.openBox('myfavourites');
  Hive.openBox('settings');
  await HomeApi.setCountry();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => MusicPlayer()),
    ChangeNotifierProvider(create: (_) => LanguageProvider(prefs)),
    ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
    ChangeNotifierProvider(create: (_) => AudioQualityProvider(prefs))
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    Track? song = context.watch<MusicPlayer>().song;

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Vibe Music',
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          locale: context.watch<LanguageProvider>().currentLocale,
          theme: context.watch<ThemeProvider>().lightTheme.copyWith(
                colorScheme: context.watch<ThemeProvider>().dynamicThemeMode
                    ? ColorScheme.fromSwatch(
                        primarySwatch: createMaterialColor(song
                                ?.colorPalette?.lightMutedColor ??
                            context.watch<ThemeProvider>().primaryColor.light))
                    : lightDynamic ??
                        ColorScheme.fromSwatch(
                                primarySwatch: createMaterialColor(context
                                    .watch<ThemeProvider>()
                                    .primaryColor
                                    .light))
                            .harmonized(),
              ),
          darkTheme: context.watch<ThemeProvider>().darkTheme.copyWith(
                colorScheme: context.watch<ThemeProvider>().dynamicThemeMode
                    ? ColorScheme.fromSwatch(
                        primarySwatch: createMaterialColor(song
                                ?.colorPalette?.darkMutedColor ??
                            context.watch<ThemeProvider>().primaryColor.dark))
                    : darkDynamic ??
                        (ColorScheme.fromSwatch(
                            primarySwatch: createMaterialColor(context
                                .watch<ThemeProvider>()
                                .primaryColor
                                .dark))),
              ),
          themeMode: context.watch<ThemeProvider>().themeMode,
          home: const Directionality(
              textDirection: TextDirection.ltr, child: MainScreen()),
        );
      },
    );
  }
}

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}
