import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'dart:typed_data';

class StorageService {
  final SupabaseClient _client = SupabaseService().client;

  Future<void> uploadFile(
    String bucket,
    String path,
    Uint8List fileBytes,
  ) async {
    try {
      await _client.storage.from(bucket).uploadBinary(path, fileBytes);
      print('Arquivo enviado para $bucket/$path');
    } catch (e) {
      print('Erro ao enviar arquivo: ' + e.toString());
      rethrow;
    }
  }

  Future<Uint8List?> downloadFile(String bucket, String path) async {
    try {
      final response = await _client.storage.from(bucket).download(path);
      print('Arquivo baixado de $bucket/$path');
      return response;
    } catch (e) {
      print('Erro ao baixar arquivo: ' + e.toString());
      rethrow;
    }
  }
}
