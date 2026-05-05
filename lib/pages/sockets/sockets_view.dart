import 'package:flutter/material.dart';
import 'package:notif_analytics/pages/chat_socket/socket.dart';

class SocketsView extends StatelessWidget {
  static const String route = '/sockets';

  const SocketsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chatSocket = ChatSocket();
    chatSocket.StartSocket();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sockets'),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Socket tasks',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => chatSocket.task1(),
                child: const Text('task 1'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => chatSocket.task2(),
                child: const Text('task 2'),
              ),
              // const SizedBox(height: 12),
              // FilledButton(
              //   onPressed: () => showTaskSnackBar(3),
              //   child: const Text('task 3'),
              // ),
              // const SizedBox(height: 12),
              // FilledButton(
              //   onPressed: () => showTaskSnackBar(4),
              //   child: const Text('task 4'),
              // ),
              // const SizedBox(height: 12),
              // FilledButton(
              //   onPressed: () => showTaskSnackBar(5),
              //   child: const Text('task 5'),
              // ),
              // const SizedBox(height: 12),
              // FilledButton(
              //   onPressed: () => showTaskSnackBar(6),
              //   child: const Text('task 6'),
              // ),
              // const SizedBox(height: 12),
              // FilledButton(
              //   onPressed: () => showTaskSnackBar(7),
              //   child: const Text('task 7'),
              // ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
