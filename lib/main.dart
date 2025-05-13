import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'music_screen.dart';
import 'music_view_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MusicViewModel(),
      child: MaterialApp(
        title: 'Flutter Music App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const MusicScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
