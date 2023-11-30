import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _msgController = TextEditingController();
  ServerSocket? serverSocket;
  Socket? clientSocket;
  int port = 5555;
  StringBuffer logcat = StringBuffer();

  void startServer() async {
    setState(() {
      logcat.write("Start Server : waiting client...\n");
    });

    serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port, shared: true);
    serverSocket?.listen((socket) {
      setState(() {
        clientSocket = socket;
        logcat.write(
            "Socket Connected - ${socket.remoteAddress.address}:${socket.remotePort}\n");
      });

      socket.listen(
        (onData) {
          setState(() {
            logcat.write("Receive : ${utf8.decode(onData)}\n");
          });
        },
        onDone: () {
          disconnect();
        },
        onError: (e) {
          logcat.write("exception : $e\n");
          disconnect();
        },
      );
    });
  }

  void stopServer() {
    serverSocket?.close();

    setState(() {
      serverSocket = null;
      logcat.write("Stop Server\n");
    });
  }

  void disconnect() {
    clientSocket?.close();

    setState(() {
      clientSocket = null;
      logcat.write("Socket Disconnected\n");
    });
  }

  void sendMessage() {
    if (_msgController.text.isEmpty) return;

    clientSocket?.write(_msgController.text);

    setState(() {
      logcat.write("Send : ${_msgController.text}\n");
      _msgController.clear();
    });
  }

  @override
  void initState() {
    super.initState();

    startServer();
  }

  @override
  void dispose() {
    super.dispose();

    stopServer();

    _msgController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Socket Server(서버)')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            controllerView(),
            logcatView(),
            sendMessageView(),
          ],
        ),
      ),
    );
  }

  Widget controllerView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(
          clientSocket == null ? 'DisConnected' : 'Connected',
          style: TextStyle(
            color: clientSocket == null ? Colors.red : Colors.green,
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: () {
            if (serverSocket == null) {
              startServer();
            } else {
              stopServer();
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(serverSocket == null ? '서버 시작' : '서버 중지'),
        ),
      ],
    );
  }

  Widget logcatView() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: Text(
              logcat.toString(),
            ),
          ),
        ),
      ),
    );
  }

  Widget sendMessageView() {
    return Card(
      child: ListTile(
        title: TextField(
          controller: _msgController,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.send),
          color: Colors.blue,
          disabledColor: Colors.grey,
          onPressed: (clientSocket != null) ? sendMessage : null,
        ),
      ),
    );
  }
}
