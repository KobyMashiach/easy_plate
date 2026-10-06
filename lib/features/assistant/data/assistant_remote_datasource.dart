import 'package:flutter/foundation.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/ai_auth_header.dart';
import '../../../core/network/http_calls.dart';
import '../domain/assistant_models.dart';

/// The assistant's wire to Gemini through the app's proxy: one Interactions
/// API call per turn, with the function declarations attached. The server
/// keeps the conversation (`previous_interaction_id`), so a turn carries only
/// what is new: the user's words, or the results of the calls the model
/// asked for.
abstract class AssistantRemoteDataSource {
  /// Sends a user message, continuing [previousInteractionId] when set.
  Future<AssistantTurn> send({
    required String message,
    required String systemInstruction,
    required List<Map<String, dynamic>> tools,
    String? previousInteractionId,
  });

  /// Returns the results of the calls the last turn asked for.
  Future<AssistantTurn> sendResults({
    required String previousInteractionId,
    required Map<String, ToolResult> results,
    required List<Map<String, dynamic>> tools,
    required Map<String, String> callNames,
  });
}

class GeminiAssistantRemoteDataSource implements AssistantRemoteDataSource {
  final HttpCalls httpCalls;

  static const feature = 'assistant';

  GeminiAssistantRemoteDataSource({HttpCalls? httpCalls})
    : httpCalls = httpCalls ?? _defaultHttpCalls();

  static HttpCalls _defaultHttpCalls() {
    if (ApiConfig.usesProxy) {
      return HttpCalls(
        baseUrl: ApiConfig.aiBaseUrl,
        headerProvider: aiProxyAuthHeader,
      );
    }
    return HttpCalls(
      baseUrl: ApiConfig.aiBaseUrl,
      headers: {'x-goog-api-key': ApiConfig.geminiApiKey},
    );
  }

  @override
  Future<AssistantTurn> send({
    required String message,
    required String systemInstruction,
    required List<Map<String, dynamic>> tools,
    String? previousInteractionId,
  }) {
    return _call({
      'model': ApiConfig.model,
      'system_instruction': systemInstruction,
      'input': message,
      'previous_interaction_id': ?previousInteractionId,
      'tools': tools,
      if (ApiConfig.thinkingLevel.isNotEmpty)
        'generation_config': {'thinking_level': ApiConfig.thinkingLevel},
    });
  }

  @override
  Future<AssistantTurn> sendResults({
    required String previousInteractionId,
    required Map<String, ToolResult> results,
    required List<Map<String, dynamic>> tools,
    required Map<String, String> callNames,
  }) {
    return _call({
      'model': ApiConfig.model,
      'previous_interaction_id': previousInteractionId,
      'input': [
        for (final entry in results.entries)
          {
            'type': 'function_result',
            'call_id': entry.key,
            'name': callNames[entry.key],
            'result': entry.value.data,
          },
      ],
      'tools': tools,
      if (ApiConfig.thinkingLevel.isNotEmpty)
        'generation_config': {'thinking_level': ApiConfig.thinkingLevel},
    });
  }

  Future<AssistantTurn> _call(Map<String, dynamic> body) async {
    if (!ApiConfig.isConfigured) {
      throw const AppException(
        AppErrorType.unauthorized,
        message: 'GEMINI_API_KEY is not configured',
      );
    }
    Map<String, dynamic>? data;
    for (var attempt = 0; ; attempt++) {
      try {
        final response = await httpCalls.post(
          ApiConfig.interactionsPath,
          data: body,
          headers: const {'x-easyplate-feature': feature},
        );
        data = response?.data as Map<String, dynamic>?;
        break;
      } on AppException catch (e) {
        if (e.type != AppErrorType.overloaded || attempt >= 2) rethrow;
        debugPrint('Assistant: Gemini busy, retrying (${attempt + 1})');
        await Future<void>.delayed(Duration(milliseconds: 600 << attempt));
      }
    }
    if (data == null) throw const AppException(AppErrorType.parsingFailed);
    return parseTurn(data);
  }

  /// `steps` holds thoughts, function calls and the model's text; the text
  /// blocks are joined, the calls collected in order.
  @visibleForTesting
  static AssistantTurn parseTurn(Map<String, dynamic> data) {
    final id = data['id'] as String? ?? '';
    final text = StringBuffer();
    final calls = <ToolCall>[];
    for (final step in (data['steps'] as List?) ?? const []) {
      if (step is! Map) continue;
      switch (step['type']) {
        case 'function_call':
          final raw = step['arguments'];
          calls.add(
            ToolCall(
              id: step['id'] as String? ?? 'call_${calls.length}',
              name: step['name'] as String? ?? '',
              arguments: raw is Map
                  ? raw.cast<String, dynamic>()
                  : const <String, dynamic>{},
            ),
          );
        case 'model_output':
          for (final block in (step['content'] as List?) ?? const []) {
            if (block is Map && block['text'] is String) {
              text.write(block['text']);
            }
          }
      }
    }
    if (id.isEmpty) throw const AppException(AppErrorType.parsingFailed);
    return AssistantTurn(
      interactionId: id,
      text: text.toString().trim(),
      toolCalls: calls,
    );
  }
}
