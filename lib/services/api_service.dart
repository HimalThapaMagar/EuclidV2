import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Make sure to use HTTPS for Render
  static const String baseUrl = 'https://euclidv2.onrender.com';
  static const String calculateEndpoint = '/calculate/';

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

    // Use a client to handle redirects properly
    final client = http.Client();
    try {
      print('Sending request...');
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: "${response.body}"'); // Print the exact response body
      print('Response body length: ${response.body.length}');
      
      // Check for successful response
      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          // Handle empty response
          print('Warning: Server returned empty response body');
          return {'expression': 'No data', 'result': 0};
        }
        
        try {
          return json.decode(response.body);
        } catch (e) {
          print('JSON parsing error: $e');
          // Return a fallback response
          return {'expression': 'Error parsing', 'result': 0};
        }
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