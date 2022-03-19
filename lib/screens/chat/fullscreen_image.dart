import 'package:flutter/material.dart'; 

class FullScreenImage extends StatelessWidget {
  final Widget image; 
  final Widget appBarTitle; 
  final String heroTag; 
  const FullScreenImage({ 
    required this.image, 
    required this.appBarTitle, 
    required this.heroTag, 
    Key? key 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: appBarTitle, 
      ),
      body: Center(
        child: Hero(
          tag: heroTag, 
          child: image, 
        ) 
      )
    ); 
  }
}