import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

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

  Map<String, dynamic> protocolData = {
    "protocol": {
      "name": "YQ-COM2",
      "version": "1.0",
      "remotefunction": {
        "name": "指令名",
        "signature": "Rd+f … ew==",
        "fingerprint": "31:F2:17:E5:25:4D:61:EF:AF:4F:29:CF:56:2B:F5:86:DC:DE:F2:65",
        "tracecode": "112233",
        "input": {
          "parameter1": "value1",
          "parameter2": "value2"
        }
      }
    }
  };

  void deviceDiscover() async {
    // 创建 JSON 格式数据
    final jsonString = jsonEncode(protocolData);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));

    // 创建 UDP Socket
    RawDatagramSocket socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      10001,
      reuseAddress: true,
    );

    // 设置广播选项
    socket.broadcastEnabled = true;

    // 发送广播
    socket.send(
      bytes,
      InternetAddress("255.255.255.255"), // 广播地址
      10001, // 目标端口
    );

    print("✅ 已发送广播消息：\n${const JsonEncoder.withIndent('  ').convert(protocolData)}");

    // 监听响应
    socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = socket.receive();
        if (datagram != null) {
          // 解析接收到的数据
          final response = utf8.decode(datagram.data);
          final sourceAddress = datagram.address.address;
          final sourcePort = datagram.port;

          try {
            // 解析 JSON
            final jsonResponse = jsonDecode(response);

            print("\n🎯 收到来自 ${sourceAddress}:${sourcePort} 的响应：");
            print(const JsonEncoder.withIndent('  ').convert(jsonResponse));

            // 这里可以添加具体的响应处理逻辑
            if (jsonResponse['status'] == 'success') {
              handleSuccessResponse(jsonResponse);
            } else {
              handleErrorResponse(jsonResponse);
            }
          } catch (e) {
            print("❌ JSON 解析失败：$e");
            print("原始响应数据：$response");
          }
        }
      }
    });
  }

  void handleSuccessResponse(Map<String, dynamic> response) {
    // 处理成功响应
    print("🟢 设备处理成功：");
    print("跟踪码：${response['tracecode']}");
    print("结果：${response['result']}");
  }

  void handleErrorResponse(Map<String, dynamic> response) {
    // 处理错误响应
    print("🔴 设备返回错误：");
    print("错误码：${response['error_code']}");
    print("错误信息：${response['error_message']}");
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
              deviceDiscover();
            },
          ),
          // 前进按钮
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded), // 前进图标
            onPressed: () {
              // 调用WebViewController的goForward方法，实现页面前进
              _controller.goForward();
              // 发送测试消息给第一个设备

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