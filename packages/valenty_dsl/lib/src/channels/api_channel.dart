import 'channel.dart';

/// Channel for API-based interactions (e.g., REST, GraphQL).
abstract class ApiChannel implements Channel {
  @override
  String get name => 'API';
}
