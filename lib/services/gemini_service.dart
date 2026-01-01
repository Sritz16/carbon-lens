import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class CarbonBrain {
  // ⚠️ PASTE YOUR API KEY HERE (The one you used for "Key Finder")
  static const apiKey = 'AIzaSyB2Gv_k4xPKmMuFBS_OtFRBkHIyne18ts8';

  Future<String> analyzeCarbonFootprint(String imagePath) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    
    final imageBytes = await File(imagePath).readAsBytes();
    final prompt = TextPart("""
      You are the backend for 'Carbon Shadow Tracker'. 
      Analyze this image and identify the main food or object.
      
      Return ONLY a JSON object (no markdown, no extra text) with this format:
      {
        "item_name": "Beef Burger",
        "carbon_score": 85,  (0-100, where 100 is very high carbon/dark shadow)
        "shadow_color": "dark_red", (options: dark_red, grey, light_green)
        "nudge_text": "Swap for a Portobello Burger? Save 85% shadow.",
        "tree_analogy": "This equals 2 trees working for a month."
      }
    """);

    final imagePart = DataPart('image/jpeg', imageBytes);

    try {
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);
      return response.text ?? "{}";
    } catch (e) {
      print("❌ Gemini Error: $e");
      return "{}"; // Return empty JSON on fail
    }
  }
}