import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocket {
  IO.Socket? socket;

  void StartSocket() {
    if (socket != null) return;

    const String baseUrl = "http://192.168.50.196:3000";
    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    socket?.onConnect((data) {
      debugPrint('connected to server');
    });

    socket?.onDisconnect((data) {
      debugPrint('disconnected from server');
    });

    socket?.onConnectError((data) {
      debugPrint('error from server: $data');
    });

    socket?.connect();
  }

  void task1() {
    socket?.off('username_confirmed');
    socket?.once('username_confirmed', (data) {
      debugPrint('username confirmed: ${data['username']}');
    });
    socket?.emit('set_username', 'Abdullah');
  }

  void task2() {
    socket?.off('user_joined');
    socket?.once('user_joined', (data) {
      debugPrint('user joined: ${data['username']}');
      debugPrint('user member count: ${data['memberCount']}');
    });

    socket?.off('room_joined');
    socket?.once('room_joined', (data) {
      debugPrint('joined room id: ${data['roomId']}');
      debugPrint('joined room name: ${data['roomName']}');
      debugPrint('joined history: ${data['history']}');
      debugPrint('joined members: ${data['members'][0]['username']}');
    });
    socket?.emit('join_room', {'roomId': 'general'});
  }

  void task3() {
    socket?.emitWithAck(
      'send_message',
      {'roomId': 'general', 'text': 'Hello, everyone!'},
      ack: (data) {
        debugPrint('message sent: ${data['id']}');
        debugPrint('message sent: ${data['roomId']}');
        debugPrint('message sent: ${data['text']}');
        debugPrint('message sent: ${data['username']}');
        debugPrint('message sent: ${data['timestamp']}');
      },
    );
  }

  // void task4() {
  //   socket?.emit('typing', {'roomId': 'general', 'isTyping': true});
  //   socket?.emit('typing', {'roomId': 'general', 'isTyping': false});
  // }
}
