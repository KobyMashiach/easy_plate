import '../../../../core/constants/api_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/ai_auth_header.dart';
import '../../../../core/network/http_calls.dart';

/// One Remote Config parameter as the console holds it: its default value
/// (what the app reads), its type, the group it sits in and the Hebrew
/// description written next to it in the console.
class RemoteParam {
  final String name;
  final String group;
  final String description;
  final String valueType;
  final String value;

  const RemoteParam({
    required this.name,
    required this.group,
    required this.description,
    required this.valueType,
    required this.value,
  });

  bool get isBoolean => valueType == 'BOOLEAN';
  bool get isNumber => valueType == 'NUMBER';

  /// A feature flag: 0 hidden, 1 coming soon, 2 everyone, 3 Premium.
  bool get isFeatureFlag => name.startsWith('ff_');

  static RemoteParam fromJson(Map<String, dynamic> json) => RemoteParam(
    name: (json['name'] as String?) ?? '',
    group: (json['group'] as String?) ?? '',
    description: (json['description'] as String?) ?? '',
    valueType: (json['valueType'] as String?) ?? 'STRING',
    value: (json['value'] as String?) ?? '',
  );

  RemoteParam withValue(String value) => RemoteParam(
    name: name,
    group: group,
    description: description,
    valueType: valueType,
    value: value,
  );
}

/// What the editor needs: the template as a list, and one value published.
abstract class RemoteConfigEditor {
  Future<List<RemoteParam>> fetch();
  Future<List<RemoteParam>> set(String name, String value);
}

/// Reads and writes the console's template through the `adminRemoteConfig`
/// function, which holds the Admin SDK and admits the administrator only.
class AdminRemoteConfigDataSource implements RemoteConfigEditor {
  final HttpCalls _calls;

  AdminRemoteConfigDataSource({HttpCalls? calls})
    : _calls =
          calls ??
          HttpCalls(
            baseUrl: ApiConfig.adminRemoteConfigUrl,
            headerProvider: aiProxyAuthHeader,
          );

  Future<List<RemoteParam>> _post(Map<String, dynamic> body) async {
    if (!ApiConfig.usesProxy) {
      throw const AppException(
        AppErrorType.unauthorized,
        message: 'Remote Config editing needs the Cloud Functions deploy',
      );
    }
    final response = await _calls.post('', data: body);
    final data = response?.data;
    final raw = data is Map ? data['parameters'] : null;
    if (raw is! List) {
      throw const AppException(
        AppErrorType.parsingFailed,
        message: 'No parameters',
      );
    }
    return [
      for (final item in raw)
        if (item is Map) RemoteParam.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<List<RemoteParam>> fetch() => _post({'action': 'get'});

  /// Publishes one value and returns the whole template as published.
  @override
  Future<List<RemoteParam>> set(String name, String value) =>
      _post({'action': 'set', 'name': name, 'value': value});
}
