import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skin_detection_app/page/MainScreen/mainScreen.dart';

import 'approutes.dart';

void main() async{
  runApp(


    const  MyApp()
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( initialRoute: '/',
      getPages: AppPages.routes,
      defaultTransition: Transition.fade,

      title: 'Skin Detection',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

