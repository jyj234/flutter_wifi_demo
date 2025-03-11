import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:io';
import 'dart:typed_data';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 此widget是应用程序的根
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 设置应用程序的主题颜色
      theme: ThemeData(
        // 使用深紫色作为主题颜色的种子
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        // 启用Material Design 3
        useMaterial3: true,
      ),
      // 将WebViewExample作为应用程序的首页
      home: const WebViewExample(),
    );
  }
}

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});
  @override
  WebViewExampleState createState() => WebViewExampleState();
}

class WebViewExampleState extends State<WebViewExample> {
  // 声明一个延迟初始化的WebViewController
  late final WebViewController _controller;
  static final Map<String, InternetAddress> _devices = {};
  static RawDatagramSocket? _discoverySocket;

  static Future<void> discoverDevices() async {
    _devices.clear();
    _discoverySocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _discoverySocket!.broadcastEnabled = true;

    // 发送广播包
    final discoveryPacket = Uint8List.fromList('DISCOVER'.codeUnits);
    _discoverySocket!.send(
      discoveryPacket,
      InternetAddress('255.255.255.255'),
      8888,
    );

    // 监听响应
    _discoverySocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _discoverySocket!.receive();
        if (datagram != null) {
          final deviceId = String.fromCharCodes(datagram.data);
          _devices[deviceId] = datagram.address;
          print('Found device: $deviceId (${datagram.address.address})');
        }
      }
    });

    // 10秒后停止发现
    await Future.delayed(Duration(seconds: 10));
    _discoverySocket?.close();
  }

  // 定向发送数据
  static Future<void> sendToDevice(String deviceId, String message) async {
    final address = _devices[deviceId];
    if (address == null) throw Exception('Device not found');

    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final data = Uint8List.fromList(message.codeUnits);
    socket.send(data, address, 8889);
    socket.close();
  }
  @override
  void initState() {
    super.initState();
    // 初始化WebViewController
    // 创建一个WebViewController对象
    _controller = WebViewController()
    // 允许WebView执行JavaScript
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
    // 加载指定的网页URL
      ..loadRequest(Uri.parse('https://www.thinksigncloud.com'));

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 设置AppBar
      appBar: AppBar(
        // 设置AppBar中的按钮操作
        actions: [
          // 后退按钮
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded), // 后退图标
            onPressed: () {
              // 调用WebViewController的goBack方法，实现页面后退
              _controller.goBack();
              discoverDevices();
            },
          ),
          // 前进按钮
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded), // 前进图标
            onPressed: () {
              // 调用WebViewController的goForward方法，实现页面前进
              _controller.goForward();
              // 发送测试消息给第一个设备
              if (WebViewExampleState._devices.isNotEmpty) {
                final targetId = WebViewExampleState._devices.keys.first;
                print('Sending to $targetId');
                WebViewExampleState.sendToDevice(targetId, 'Hello from Flutter!');
              }
            },
          ),
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh), // 刷新图标
            onPressed: () {
              // 调用WebViewController的reload方法，实现页面刷新
              _controller.reload();
            },
          ),
        ],
        // 设置AppBar的标题
        title: const Text('Test Webview'),
      ),
      // 设置页面主体为WebViewWidget
      body: WebViewWidget(controller: _controller),
    );
  }
}