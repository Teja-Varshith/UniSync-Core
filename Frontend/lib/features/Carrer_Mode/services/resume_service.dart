import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:UniSync/models/portifolo_model.dart';

/// Handles resume PDF picking, text extraction, and Groq-based auto-fill.
class ResumeService {
  // ⚠️  Replace with your own key or move to a secure config / env variable.
  static const _groqApiKey =
      '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';
  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';

  /// Pick a PDF file and extract its raw text.
  /// Returns `null` if user cancels.
  static Future<String?> pickAndExtractText() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();

    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final text = extractor.extractText();
    document.dispose();

    return text.trim();
  }

  /// Send the extracted resume text to Groq and get a structured
  /// [PortifoloModel] back (only the fields the LLM could parse).
  static Future<PortifoloModel> parseWithGroq(String resumeText) async {
    final systemPrompt = '''
You are a resume parser. Given the raw text extracted from a resume PDF, 
return a JSON object with these exact keys (omit a key if you cannot find data for it):

{
  "name": "string",
  "role": "string — professional title / headline",
  "tagline": "string — short punchy one-liner",
  "email": "string",
  "phone": "string",
  "about": "string — 2-3 sentence professional summary",
  "projects": [
    { "name": "string", "description": "string", "tags": ["string"] }
  ],
  "skills": [
    { "name": "string", "isHighlighted": true/false }
  ],
  "experience": [
    { "role": "string", "org": "string", "date": "string", "isActive": true/false }
  ],
  "achievements": [
    { "title": "string", "description": "string", "date": "string" }
  ],
  "certifications": [
    { "name": "string", "issuer": "string", "date": "string", "credentialUrl": "string or null" }
  ]
}

Mark the top 2-3 most relevant skills as isHighlighted: true.
Mark the most recent experience as isActive: true.
Return ONLY valid JSON, no markdown fences or explanation.
''';

    final response = await http.post(
      Uri.parse(_groqUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_groqApiKey',
      },
      body: json.encode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': resumeText},
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.1,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Groq API error ${response.statusCode}: ${response.body}');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final content = body['choices'][0]['message']['content'] as String;
    final parsed = json.decode(content) as Map<String, dynamic>;

    return PortifoloModel.fromMap(parsed);
  }

  /// Send the extracted resume text to Groq and get an ATS analysis
  /// returning [ResumeAnalysisResult].
  static Future<ResumeAnalysisResult> analyzeResume(String resumeText) async {
    final systemPrompt = '''
You are an expert ATS (Applicant Tracking System) and senior technical recruiter.
Given the raw text extracted from a resume PDF, return a JSON object with this exact schema:

{
  "atsScore": integer (0 to 100 representing how well formatted and impactful this is),
  "pros": ["string", "string"],
  "cons": ["string", "string"],
  "summary": "string - a detailed 3-4 sentence comprehensive evaluation"
}

Provide actionable, sharp, and highly specific feedback. Return ONLY valid JSON.
''';

    final response = await http.post(
      Uri.parse(_groqUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_groqApiKey',
      },
      body: json.encode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': resumeText},
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.2, // Slightly higher for more creative/varied summary
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Groq API error ${response.statusCode}: ${response.body}');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final content = body['choices'][0]['message']['content'] as String;
    final parsed = json.decode(content) as Map<String, dynamic>;

    return ResumeAnalysisResult.fromMap(parsed);
  }
}

class ResumeAnalysisResult {
  final int atsScore;
  final List<String> pros;
  final List<String> cons;
  final String summary;

  ResumeAnalysisResult({
    required this.atsScore,
    required this.pros,
    required this.cons,
    required this.summary,
  });

  factory ResumeAnalysisResult.fromMap(Map<String, dynamic> map) {
    return ResumeAnalysisResult(
      atsScore: map['atsScore']?.toInt() ?? 0,
      pros: List<String>.from(map['pros'] ?? []),
      cons: List<String>.from(map['cons'] ?? []),
      summary: map['summary'] ?? '',
    );
  }
}
