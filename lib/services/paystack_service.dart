// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paystack_withdrawal/constants/api_keys.dart';

class PaystackService {
  static const String _baseUrl = "https://api.paystack.co";

  // Corrected method name and parameters
  Future<String?> createTransferRecipient({
    required String bankNumber,
    required String bankCode,
    required String accountName,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/transferrecipient');

      // Update the request body with dynamic values
      final requestBody = {
        "type": "nuban",
        "name": accountName,
        "account_number": bankNumber,
        "bank_code": bankCode,
        "currency": "NGN",
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${ApiKeys.payStackLiveKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final responseBody = json.decode(response.body);

        // Ensure the expected structure of the response
        if (responseBody.containsKey('data') &&
            responseBody['data'] is Map<String, dynamic>) {
          final recipientCode = responseBody['data']['recipient_code'];
          return recipientCode;
        } else {
          print('Error: Unexpected response structure');
          return null;
        }
      } else {
        print('Error creating transfer recipient: ${response.statusCode}');
        print(response.body);
        return null;
      }
    } on FormatException catch (e) {
      print('Error decoding JSON: $e');
      return null;
    } catch (error) {
      print('Error creating transfer recipient: $error');
      return null;
    }
  }

  // Updated method parameters to match the createTransferRecipient method
  Future<String?> initiateTransfer({
    required double amount,
    required String recipientCode,
    required String reference,
    String? selectedBankName,
    String? selectedAccountName,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/transfer');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${ApiKeys.payStackLiveKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "source": "balance",
          "amount": 100 * amount,
          "reference": reference,
          "recipient": recipientCode,
          "reason": "Wallet Withdrawal"
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final transferCode = responseBody['data']['transfer_code'];
        print(selectedBankName);
        return transferCode;
      } else {
        print('Error initiating transfer: ${response.statusCode}');
        print(response.body);
        return null;
      }
    } on FormatException catch (e) {
      print('Error decoding JSON: $e');
      return null;
    } catch (error) {
      print('Error initiating transfer: $error');
      return null;
    }
  }
}
