import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skin_detection_app/page/HomePage.dart';

import '../page/Aboutus/aboutcreaters.dart';
import '../page/DoandDont/Doees.dart';



class NavigatorDrawer extends StatelessWidget {
  const NavigatorDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const CreateDrawerHeader(),
          DrawerItem(
            icon: Icons.home,
            text: 'Home',
            onTap: () =>
               Get.to(Homepage())
          ),
          DrawerItem(
            icon: Icons.rule,
            text: 'Do\'s and Don\'ts',
            onTap: () => Get.to(Dos())

          ),

          DrawerItem(
            icon: Icons.assignment_ind_outlined,
            text: 'About Us',
            onTap: () =>
               Get.to(AboutUs())
          )
        ],
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget DrawerItem({
    //Function to show the item in the drawer
    IconData? icon,
    String? text,
    GestureTapCallback? onTap,
  }) {
    return ListTile(
      title: Row(children: [
        Icon(icon),
        Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Text(text!),
        ),
      ]),
      onTap: onTap,
    );
  }
}

class CreateDrawerHeader extends StatelessWidget {
  //class for the header of the
  const CreateDrawerHeader({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(
          color: Colors.purple,
          image: DecorationImage(
            image: AssetImage("assets/images/skindisease.jpg"),
            fit: BoxFit.cover,
          )),
      child: Stack(children: const [
        Positioned(
            bottom: 15,
            left: 18,
            child: Text(
              "Skin Disease Detection",
              style: TextStyle(
                  color: Color.fromARGB(255, 191, 21, 214),
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            )),
      ]),
    );
  }
}
