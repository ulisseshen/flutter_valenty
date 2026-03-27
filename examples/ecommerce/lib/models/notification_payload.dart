class NotificationPayload {
  const NotificationPayload({
    required this.title,
    required this.body,
    this.data = const {},
  });

  final String title;
  final String body;
  final Map<String, dynamic> data;
}
