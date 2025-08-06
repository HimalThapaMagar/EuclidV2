import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Base URL - change this when deploying to cloud
  static const String baseUrl = 'http://localhost:8080';
  
  // Endpoint for sending drawings
  static const String calculateEndpoint = '/calculate';

  /// Uploads a drawing image to the backend for processing
  /// Returns the calculation result as a Map
  static Future<Map<String, dynamic>> uploadDrawing(Uint8List imageBytes) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$calculateEndpoint'));

      // Add the image file to the request
      final multipartFile = http.MultipartFile.fromBytes(
        'drawing',  // Field name that the server expects
        imageBytes,
        filename: 'drawing.png',
        contentType: MediaType('image', 'png'),
      );
      request.files.add(multipartFile);

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Check for successful response
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to process drawing: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error uploading drawing: $e');
      throw Exception('Failed to communicate with the server: $e');
    }
  }
}