import 'package:flutter/material.dart';

PreferredSizeWidget AccessAppBar(context,title,icon) {
  return AppBar(
    centerTitle: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    title:title,
    iconTheme: IconThemeData(color: Colors.brown),
    actions: [icon],
  );
}