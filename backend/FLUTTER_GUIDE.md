# Socket.IO Test Server — Flutter Integration Guide

## Running the server

```bash
node server.js
```

Server starts on `http://192.168.50.196:3000`.
To test from a physical device or emulator, replace `localhost` with your
machine's local IP (e.g. `192.168.1.x`). Find it with `ipconfig` (Windows)
or `ifconfig` / `ip a` (Mac/Linux).

---

## Flutter setup

```yaml
# pubspec.yaml
dependencies:
  socket_io_client: ^2.0.3+1
```

---

## Connecting

dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

final socket = IO.io(
  'http://192.168.1.x:3000', // replace with your machine IP
  IO.OptionBuilder()
    .setTransports(['websocket'])
    .disableAutoConnect()
    .setReconnectionAttempts(5)
    .setReconnectionDelay(2000)
    .build(),
);

socket.onConnect((_) => print('Connected: ${socket.id}'));
socket.onDisconnect((_) => print('Disconnected'));
socket.onConnectError((e) => print('Error: $e'));

socket.connect();


---

## Events reference

### 1. Set your username (call right after connect)
```dart
socket.emit('set_username', 'Abdullah');

socket.once('username_confirmed', (data) {
  print('Username set: ${data['username']}');
});
```

### 2. Get room list (server sends this automatically on connect)
```dart
socket.on('room_list', (data) {
  // data is a List of { id, name, memberCount }
  final rooms = List<Map>.from(data);
  print(rooms); // [{ id: 'general', name: 'General', memberCount: 1 }, ...]
});
```

### 3. Join a room
```dart
socket.emit('join_room', {'roomId': 'general'});

socket.once('room_joined', (data) {
  print('Joined: ${data['roomName']}');
  print('History: ${data['history']}'); // last 20 messages
  print('Members: ${data['members']}');
});

// Other clients in the room will receive:
socket.on('user_joined', (data) {
  print('${data['username']} joined (${data['memberCount']} members)');
});
```

### 4. Send a message (with acknowledgement)
```dart
socket.emitWithAck(
  'send_message',
  {'roomId': 'general', 'text': 'Hey everyone!'},
  ack: (response) {
    if (response['status'] == 'ok') {
      print('Saved with id: ${response['messageId']}');
    } else {
      print('Error: ${response['message']}');
    }
  },
);
```

### 5. Receive messages
```dart
socket.on('new_message', (data) {
  // data: { id, roomId, text, username, timestamp }
  print('[${data['username']}]: ${data['text']}');
});
```

### 6. Typing indicator
```dart
// Send while user is typing
socket.emit('typing', {'roomId': 'general', 'isTyping': true});
// Send when they stop
socket.emit('typing', {'roomId': 'general', 'isTyping': false});

// Receive from others
socket.on('user_typing', (data) {
  if (data['isTyping']) {
    print('${data['username']} is typing...');
  }
});
```

### 7. Ping — test emitWithAck round-trip
```dart
socket.emitWithAck('ping_server', {'hello': 'world'}, ack: (res) {
  print('Pong! serverTime: ${res['serverTime']}');
  print('Echo: ${res['echo']}'); // your original payload echoed back
});
```

### 8. Simulate a forced disconnect (test reconnection)
```dart
// Server will drop your socket after 2–5 seconds at random
socket.emit('simulate_disconnect');

socket.once('disconnect_incoming', (data) {
  print('Server will drop us in ${data['inMs']}ms — brace yourself');
});

// Your onDisconnect and auto-reconnect logic will fire after the drop
socket.on('reconnect', (_) {
  print('Reconnected! Re-join rooms here.');
  socket.emit('join_room', {'roomId': currentRoom});
});
```

### 9. Leave a room
```dart
socket.emit('leave_room', {'roomId': 'general'});
```

### 10. Error events
```dart
socket.on('error_event', (data) {
  print('Server error: ${data['message']}');
});
```

---

## Recommended ViewModel structure

```dart
class ChatViewModel extends ChangeNotifier {
  late IO.Socket _socket;
  final List<Map> messages = [];
  final List<Map> rooms = [];
  String? currentRoom;
  bool isConnected = false;

  void init(String serverUrl, String username) {
    _socket = IO.io(serverUrl,
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setReconnectionAttempts(5)
        .setReconnectionDelay(2000)
        .build(),
    );

    _socket.onConnect((_) {
      isConnected = true;
      _socket.emit('set_username', username);
      notifyListeners();
    });

    _socket.onDisconnect((_) {
      isConnected = false;
      notifyListeners();
    });

    _socket.on('room_list', (data) {
      rooms
        ..clear()
        ..addAll(List<Map>.from(data));
      notifyListeners();
    });

    _socket.on('new_message', (data) {
      messages.add(Map.from(data));
      notifyListeners();
    });

    _socket.on('reconnect', (_) {
      if (currentRoom != null) joinRoom(currentRoom!);
    });

    _socket.connect();
  }

  void joinRoom(String roomId) {
    currentRoom = roomId;
    messages.clear();
    _socket.emit('join_room', {'roomId': roomId});
    _socket.once('room_joined', (data) {
      messages.addAll(List<Map>.from(data['history']));
      notifyListeners();
    });
  }

  void sendMessage(String text) {
    if (currentRoom == null) return;
    _socket.emitWithAck(
      'send_message',
      {'roomId': currentRoom, 'text': text},
      ack: (res) {
        if (res['status'] != 'ok') print('Send failed: ${res['message']}');
      },
    );
  }

  void simulateDisconnect() => _socket.emit('simulate_disconnect');

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }
}
```

---

## Quick event map

| You emit (Flutter)    | Server receives      | Server emits back              | You receive              |
|-----------------------|----------------------|--------------------------------|--------------------------|
| `set_username`        | `set_username`       | `username_confirmed`           | your username echoed     |
| `join_room`           | `join_room`          | `room_joined` + `user_joined`  | history + members        |
| `send_message` + ack  | `send_message`       | ack callback + `new_message`   | saved id + message       |
| `typing`              | `typing`             | `user_typing` (to others)      | typing indicators        |
| `ping_server` + ack   | `ping_server`        | ack callback                   | server time + echo       |
| `simulate_disconnect` | `simulate_disconnect`| `disconnect_incoming` + drop   | disconnect + reconnect   |
| `leave_room`          | `leave_room`         | `user_left` (to others)        | —                        |
