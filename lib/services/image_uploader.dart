import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:stateful_widget/config/cloudinary_config.dart';

class ImageUploader {
  static Future<String?> upload(XFile file) async {
    try {
      final url = Uri.parse(CloudinaryConfig.uploadUrl);
      final bytes = await file.readAsBytes();
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
        ..fields['folder'] = CloudinaryConfig.folder
        ..files.add(http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: file.name,
            ));
      final resp = await request.send();
      final data = jsonDecode(await resp.stream.bytesToString());
      return data['secure_url'];
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}
