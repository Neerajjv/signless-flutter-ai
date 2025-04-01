import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey =
      "YOUR_API_KEY"; // Replace with your API Key
  final String apiUrl =
      "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent";

  Future<Map<String, dynamic>> getResponseWithChoices(
    String userInput,
    String sentiment,
  ) async {
    String prompt = """
    You are assisting a person who cannot speak. They want to respond in a "$sentiment" manner.
    Based on their transcribed speech, generate four unique responses matching the sentiment.
    Format your response as follows:
    
    Choices: ["choice1", "choice2", "choice3", "choice4"]
    
    Here is the transcribed speech: "$userInput"
    """;

    try {
      final response = await http.post(
        Uri.parse("$apiUrl?key=$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String rawText = data["candidates"][0]["content"]["parts"][0]["text"];

        // Extract choices
        RegExp choicesPattern = RegExp(r'Choices:\s*\[(.*?)\]', dotAll: true);
        Match? match = choicesPattern.firstMatch(rawText);

        if (match != null) {
          List<String> choices =
              match
                  .group(1)
                  ?.split(',')
                  .map((e) => e.trim().replaceAll('"', ''))
                  .toList() ??
              [];
          return {"choices": choices};
        } else {
          return {"choices": []};
        }
      } else {
        return {"choices": []};
      }
    } catch (e) {
      return {"choices": []};
    }
  }
}
