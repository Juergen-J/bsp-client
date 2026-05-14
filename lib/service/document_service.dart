import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

enum StaticDocumentType {
  impressum('impressum'),
  privacyPolicy('privacy-policy'),
  termsAndConditions('terms-and-conditions');

  final String value;
  const StaticDocumentType(this.value);
}

class DocumentService {
  final Dio dio;

  DocumentService({required this.dio});

  Future<Uint8List> fetchDocumentBytes(StaticDocumentType type) async {
    try {
      final response = await dio.get<List<int>>(
        '/v1/document/${type.value}',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data == null) {
        throw Exception('No data received for document ${type.value}');
      }

      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      debugPrint(
          'Error fetching document: ${e.response?.statusCode} - ${e.message}');
      rethrow;
    }
  }
}
