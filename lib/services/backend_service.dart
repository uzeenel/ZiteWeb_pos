import 'dart:io';

class BackendService {
  static Process? _serverProcess;
  static bool _isRunning = false;

  static Future<bool> startBackend() async {
    if (_isRunning) return true;

    try {
      final backendPath = 'C:/Users/nelso/pos_server';
      
      print('Starting backend from: $backendPath');
      
      final backendDir = Directory(backendPath);
      if (!await backendDir.exists()) {
        print('Backend directory not found at: $backendPath');
        return false;
      }

      final serverFile = File('$backendPath/server.js');
      if (!await serverFile.exists()) {
        print('server.js not found at: $backendPath/server.js');
        return false;
      }

      final nodeExe = await _findNodeExecutable();
      if (nodeExe == null) {
        print('Node.js not found. Please install Node.js');
        return false;
      }

      print('Using Node.js: $nodeExe');

      _serverProcess = await Process.start(
        nodeExe,
        ['server.js'],
        workingDirectory: backendPath,
        environment: {
          'PORT': '3000',
        },
      );

      _serverProcess?.stdout.listen((data) {
        final output = String.fromCharCodes(data);
        print('[Backend] $output');
        if (output.contains('Server running')) {
          _isRunning = true;
        }
      });

      _serverProcess?.stderr.listen((data) {
        print('[Backend Error] ${String.fromCharCodes(data)}');
      });

      int attempts = 0;
      while (!_isRunning && attempts < 30) {
        await Future.delayed(Duration(milliseconds: 500));
        attempts++;
      }

      if (_isRunning) {
        print('✅ Backend server started successfully on port 3000');
        return true;
      } else {
        print('⚠️ Backend server started but may not be ready');
        return false;
      }
    } catch (e) {
      print('Error starting backend: $e');
      return false;
    }
  }

  static Future<String?> _findNodeExecutable() async {
    try {
      final result = await Process.run('where', ['node'], runInShell: true);
      if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
        return result.stdout.toString().split('\n').first.trim();
      }
    } catch (e) {}

    try {
      final result = await Process.run('which', ['node'], runInShell: true);
      if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
        return result.stdout.toString().trim();
      }
    } catch (e) {}

    return null;
  }

  static Future<void> stopBackend() async {
    if (_serverProcess != null) {
      _serverProcess?.kill();
      _serverProcess = null;
      _isRunning = false;
      print('Backend server stopped');
    }
  }
}
