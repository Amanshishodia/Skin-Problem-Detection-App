// ignore: file_names
import 'package:flutter/material.dart';
import 'package:skin_detection_app/page/HomePage.dart';

import '../../NavigationDrawer/navigatorDrawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);


  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Homepage(),

      ),
    );
  }
}

//---------------------------------------------------------------------

