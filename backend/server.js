const { createServer } = require('http');
const { Server } = require('socket.io');

const httpServer = createServer();
const io = new Server(httpServer, {
  cors: {
    origin: '*', // allow all origins for local dev/Flutter testing
  },
});

const PORT = 3000;

// ─── In-memory state ───────────────────────────────────────────────────────────
// rooms: { roomId: { name, messages: [], members: Set<socketId> } }
const rooms = {
  general: { name: 'General', messages: [], members: new Set() },
  flutter: { name: 'Flutter Dev', messages: [], members: new Set() },
  random:  { name: 'Random', messages: [], members: new Set() },
};

// ─── Helpers ───────────────────────────────────────────────────────────────────
function getRoomList() {
  return Object.entries(rooms).map(([id, room]) => ({
    id,
    name: room.name,
    memberCount: room.members.size,
  }));
}

function getUsersInRoom(roomId) {
  const room = rooms[roomId];
  if (!room) return [];
  return [...room.members].map((sid) => {
    const s = io.sockets.sockets.get(sid);
    return s ? { id: sid, username: s.data.username } : null;
  }).filter(Boolean);
}

function log(socketId, msg) {
  const time = new Date().toLocaleTimeString();
  console.log(`[${time}] [${socketId.slice(0, 6)}] ${msg}`);
}

// ─── Connection handler ────────────────────────────────────────────────────────
io.on('connection', (socket) => {
  log(socket.id, 'Client connected');

  // Send room list immediately on connect so Flutter can render them
  socket.emit('room_list', getRoomList());

  // ── Set username ─────────────────────────────────────────────────────────────
  // Flutter: socket.emit('set_username', 'Abdullah')
  socket.on('set_username', (username) => {
    socket.data.username = username || `User_${socket.id.slice(0, 4)}`;
    log(socket.id, `Username set to "${socket.data.username}"`);
    socket.emit('username_confirmed', { username: socket.data.username });
  });

  // ── Join room ─────────────────────────────────────────────────────────────────
  // Flutter: socket.emit('join_room', { roomId: 'general' })
  socket.on('join_room', ({ roomId }) => {
    if (!rooms[roomId]) {
      socket.emit('error_event', { message: `Room "${roomId}" does not exist` });
      return;
    }

    // Leave any previously joined rooms first
    Object.keys(rooms).forEach((rid) => {
      if (socket.rooms.has(rid)) {
        socket.leave(rid);
        rooms[rid].members.delete(socket.id);
        io.to(rid).emit('user_left', {
          username: socket.data.username,
          memberCount: rooms[rid].members.size,
        });
      }
    });

    socket.join(roomId);
    rooms[roomId].members.add(socket.id);

    log(socket.id, `Joined room "${roomId}"`);

    // Confirm to the joining client with last 20 messages as history
    socket.emit('room_joined', {
      roomId,
      roomName: rooms[roomId].name,
      history: rooms[roomId].messages.slice(-20),
      members: getUsersInRoom(roomId),
    });

    // Tell everyone else in the room
    socket.to(roomId).emit('user_joined', {
      username: socket.data.username,
      memberCount: rooms[roomId].members.size,
    });

    // Broadcast updated room list to everyone so member counts refresh
    io.emit('room_list', getRoomList());
  });

  // ── Leave room ────────────────────────────────────────────────────────────────
  // Flutter: socket.emit('leave_room', { roomId: 'general' })
  socket.on('leave_room', ({ roomId }) => {
    if (!rooms[roomId]) return;
    socket.leave(roomId);
    rooms[roomId].members.delete(socket.id);
    socket.to(roomId).emit('user_left', {
      username: socket.data.username,
      memberCount: rooms[roomId].members.size,
    });
    io.emit('room_list', getRoomList());
    log(socket.id, `Left room "${roomId}"`);
  });

  // ── Send message (with acknowledgement) ───────────────────────────────────────
  // Flutter: socket.emitWithAck('send_message', { roomId, text }, ack: (res) { ... })
  socket.on('send_message', ({ roomId, text }, callback) => {
    if (!rooms[roomId]) {
      if (typeof callback === 'function') {
        callback({ status: 'error', message: 'Room not found' });
      }
      return;
    }

    if (!text || text.trim().length === 0) {
      if (typeof callback === 'function') {
        callback({ status: 'error', message: 'Message cannot be empty' });
      }
      return;
    }

    const message = {
      id: `msg_${Date.now()}`,
      roomId,
      text: text.trim(),
      username: socket.data.username || 'Anonymous',
      timestamp: new Date().toISOString(),
    };

    rooms[roomId].messages.push(message);
    // Keep memory lean — only store last 100 messages per room
    if (rooms[roomId].messages.length > 100) {
      rooms[roomId].messages.shift();
    }

    // Broadcast to everyone in the room (including sender)
    io.to(roomId).emit('new_message', message);

    log(socket.id, `Message in "${roomId}": "${message.text}"`);

    // Acknowledge back to the sender with the saved message id
    if (typeof callback === 'function') {
      callback({ status: 'ok', messageId: message.id });
    }
  });

  // ── Typing indicator ──────────────────────────────────────────────────────────
  // Flutter: socket.emit('typing', { roomId, isTyping: true })
  socket.on('typing', ({ roomId, isTyping }) => {
    socket.to(roomId).emit('user_typing', {
      username: socket.data.username,
      isTyping,
    });
  });

  // ── Ping (for testing round-trip and emitWithAck) ─────────────────────────────
  // Flutter: socket.emitWithAck('ping', {}, ack: (res) { print(res['pong']); })
  socket.on('ping_server', (data, callback) => {
    log(socket.id, 'Ping received');
    if (typeof callback === 'function') {
      callback({ pong: true, serverTime: new Date().toISOString(), echo: data });
    }
  });

  // ── Reconnection simulation ───────────────────────────────────────────────────
  // Flutter: socket.emit('simulate_disconnect') — server will forcibly drop this socket
  // after a random delay between 2-5 seconds, letting you test onDisconnect + reconnect
  socket.on('simulate_disconnect', () => {
    const delay = Math.floor(Math.random() * 3000) + 2000; // 2000-5000ms
    log(socket.id, `Simulated disconnect in ${delay}ms`);
    socket.emit('disconnect_incoming', { inMs: delay });
    setTimeout(() => {
      log(socket.id, 'Forcibly disconnecting client (simulation)');
      socket.disconnect(true);
    }, delay);
  });

  // ── Disconnect cleanup ────────────────────────────────────────────────────────
  socket.on('disconnect', (reason) => {
    log(socket.id, `Disconnected — reason: ${reason}`);
    Object.keys(rooms).forEach((roomId) => {
      if (rooms[roomId].members.has(socket.id)) {
        rooms[roomId].members.delete(socket.id);
        io.to(roomId).emit('user_left', {
          username: socket.data.username || 'Unknown',
          memberCount: rooms[roomId].members.size,
        });
      }
    });
    io.emit('room_list', getRoomList());
  });
});

// ─── Start ─────────────────────────────────────────────────────────────────────
httpServer.listen(PORT, () => {
  console.log(`\n  Socket.IO server running on http://localhost:${PORT}\n`);
  console.log('  Available rooms: general, flutter, random');
  console.log('  Waiting for Flutter connections...\n');
});
