import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'https://euclidv2.onrender.com';
  static const String calculateEndpoint = '/calculate';

  /// Uploads a drawing image to the backend for processing
  static Future<Map<String, dynamic>> uploadDrawing(Uint8List imageBytes) async {
    try {
      print('Preparing to connect to: $baseUrl$calculateEndpoint');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$calculateEndpoint'));

      // Add the image file to the request
      final multipartFile = http.MultipartFile.fromBytes(
        'drawing',
        imageBytes,
        filename: 'drawing.png',
        contentType: MediaType('image', 'png'),
      );
      request.files.add(multipartFile);

      // Send the request
      final client = http.Client();
      try {
        print('Sending request...');
        final streamedResponse = await client.send(request);
        final response = await http.Response.fromStream(streamedResponse);
        
        print('Response status: ${response.statusCode}');
        print('Response body: "${response.body}"');
        
        // Check for successful response
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          throw Exception('Failed to process drawing: ${response.statusCode} - ${response.body}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('Error uploading drawing: $e');
      throw Exception('Failed to communicate with the server: $e');
    }
  }
}