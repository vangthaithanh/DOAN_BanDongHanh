import 'package:flutter/material.dart';

import 'frontend/trang_bat_dau.dart';
import 'frontend/dangnhap_email.dart';
import 'frontend/dangnhap_sdt.dart';
import 'frontend/matkhau_email.dart';
import 'frontend/matkhau_sdt.dart';
import 'frontend/dangki_email.dart';
import 'frontend/dangki_matkhau_email.dart';
import 'frontend/dangki_ten_email.dart';
import 'frontend/dangki_sdt.dart';
import 'frontend/dangki_matkhau_sdt.dart';
import 'frontend/dangki_ten_sdt.dart';
import 'frontend/trang_canhan.dart';
import 'frontend/them_anh_daidien.dart';
import 'frontend/cau_hoi/cau_hoi.dart';
import 'frontend/cau_hoi/cau_hoi_1.dart';
import 'frontend/cau_hoi/cau_hoi_2.dart';
import 'frontend/cau_hoi/cau_hoi_3.dart';
import 'frontend/man_hinh_cho.dart';
import 'frontend/trang_chu.dart';
import 'frontend/map.dart';
import 'frontend/trang_chia_se_camera.dart';

void main() {
  runApp(const GoMateApp());
}

class GoMateApp extends StatelessWidget {
  const GoMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoMate',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const TrangBatDauPage(),
        '/dangnhap-email': (context) => const DangNhapEmailPage(),
        '/dangnhap-sdt': (context) => const DangNhapSdtPage(),
        '/matkhau-email': (context) => const MatKhauEmailPage(),
        '/matkhau-sdt': (context) => const MatKhauSdtPage(),
        '/dangki-email': (context) => const DangKiEmailPage(),
        '/dangki-matkhau-email': (context) => const DangKiMatKhauEmailPage(),
        '/dangki-ten-email': (context) => const DangKiTenEmailPage(),
        '/dangki-sdt': (context) => const DangKiSdtPage(),
        '/dangki-matkhau-sdt': (context) => const DangKiMatKhauSdtPage(),
        '/dangki-ten-sdt': (context) => const DangKiTenSdtPage(),
        '/trang-canhan': (context) => const TrangCaNhanPage(),
        '/them-anh-daidien': (context) => const ThemAnhDaiDienPage(),
        '/cau-hoi': (context) => const CauHoiPage(),
        '/cau-hoi-1': (context) => const CauHoi1Page(),
        '/cau-hoi-2': (context) => const CauHoi2Page(),
        '/cau-hoi-3': (context) => const CauHoi3Page(),
        '/man-hinh-cho': (context) => const ManHinhChoPage(),
        '/trang-chu': (context) => const TrangChuPage(),
        '/map': (context) => const MapPage(),
        '/trang_chia_se_camera': (context) => const CameraPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
