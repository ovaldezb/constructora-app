class AppConfig {
  static const String apiUrl = String.fromEnvironment('API_URL');
  static const String userPoolId = String.fromEnvironment('USER_POOL_ID');
  static const String clientId = String.fromEnvironment('CLIENT_ID');
  static const String region = String.fromEnvironment('REGION', defaultValue: 'us-east-1');
}
