import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order.dart';
import '../models/order_item.dart';
import '../models/product.dart';
import '../ports/order_api_port.dart';

/// Real adapter that implements [OrderApiPort] using the `http` package.
///
/// This adapter communicates with a REST API backend to place and retrieve
/// orders. It demonstrates the Ports & Adapters pattern: the domain layer
/// depends only on [OrderApiPort], while this class handles all HTTP
/// serialization details.
class HttpOrderApi implements OrderApiPort {
  HttpOrderApi({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<Order> placeOrder(List<OrderItem> items) async {
    final uri = Uri.parse('$baseUrl/api/orders');

    final payload = jsonEncode(
      {
        'items': items.map((item) {
          return {
            'productId': item.product.id,
            'quantity': item.quantity,
            'lineTotal': item.lineTotal,
          };
        }).toList(),
      },
    );

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw HttpOrderApiException(
        'Failed to place order: ${response.statusCode} ${response.reasonPhrase}',
        statusCode: response.statusCode,
      );
    }

    return _parseOrder(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<Order> getOrder(String id) async {
    final uri = Uri.parse('$baseUrl/api/orders/$id');

    final response = await _client.get(uri);

    if (response.statusCode == 404) {
      throw HttpOrderApiException(
        'Order not found: $id',
        statusCode: 404,
      );
    }

    if (response.statusCode != 200) {
      throw HttpOrderApiException(
        'Failed to get order: ${response.statusCode} ${response.reasonPhrase}',
        statusCode: response.statusCode,
      );
    }

    return _parseOrder(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Parses a JSON map into an [Order] model.
  Order _parseOrder(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?) ?? [];

    return Order(
      id: json['id'] as String,
      items: itemsList.map((itemJson) {
        final item = itemJson as Map<String, dynamic>;
        final productJson = item['product'] as Map<String, dynamic>;

        return OrderItem(
          product: Product(
            id: productJson['id'] as String,
            name: productJson['name'] as String,
            unitPrice: (productJson['unitPrice'] as num).toDouble(),
            sku: (productJson['sku'] as String?) ?? '',
          ),
          quantity: item['quantity'] as int,
          lineTotal: (item['lineTotal'] as num).toDouble(),
        );
      }).toList(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String,
    );
  }
}

/// Exception thrown when an HTTP request to the Order API fails.
class HttpOrderApiException implements Exception {
  HttpOrderApiException(this.message, {required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => 'HttpOrderApiException($statusCode): $message';
}
