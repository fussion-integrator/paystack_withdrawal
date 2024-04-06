import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paystack_withdrawal/constants/api_keys.dart';
import 'package:paystack_withdrawal/constants/base_urls.dart';
import 'package:paystack_withdrawal/handlers/handler.dart';
import 'package:paystack_withdrawal/models/bank_model.dart';
import 'package:http/http.dart' as http;
import 'package:paystack_withdrawal/services/paystack_service.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController SearchEditingController = TextEditingController();
  TextEditingController accountEditingController = TextEditingController();
  TextEditingController amountEditingController = TextEditingController();
  TextEditingController narrationEditingController = TextEditingController();

  List<BanksData> banks = [];
  BanksData? selectedBank;
  String bankCode = "";
  String accountName = "";
  String bankName = "";
  String accountNumber = "";
  String initials = "";
  bool accountAvailable = false;

  Future<void> fetchBanksData() async {
    final headers = {'Authorization': 'Bearer ${ApiKeys.payStackLiveKey}'};
    final response = await http.get(
        Uri.parse("${AppBaseUrl.payStackBaseUrl}/bank?currency=NGN"),
        headers: headers); // Replace with your API endpoint

    if (response.statusCode == 200) {
      final banksResponse = banksResponseFromJson(response.body);
      setState(() {
        banks = banksResponse.data;
      });
    } else {
      throw Exception('Failed to load banks');
    }
  }

  Future<Map<String, dynamic>?> verifyAccountnumber() async {
    final url = Uri.https('api.paystack.co', '/bank/resolve', {
      'account_number': accountEditingController.text,
      'bank_code': bankCode
    });
    final headers = {
      'Authorization': 'Bearer ${ApiKeys.payStackLiveKey}',
    };
    print("verifying account number");

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print(data);
        setState(() {
          accountAvailable = true;
          accountName = data['data']['account_name'];
        });
        //return data;
      } else {
        print('Failed to resolve bank account: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error resolving bank account: $error');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchBanksData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initiatePaystackTransfer(double amount) async {
    try {
      if (accountName.isEmpty || accountNumber.isEmpty || bankCode.isEmpty) {
        Get.snackbar("Error", "Please select withdrawal bank");
        return;
      }

      // Create a recipient and get the recipient code
      final recipientCode = await PaystackService().createTransferRecipient(
        bankNumber: accountNumber,
        bankCode: bankCode,
        accountName: accountName,
      );

      print(recipientCode);

      if (recipientCode != null) {
        // Proceed to initiate the transfer using the recipient code
        final reference = _generateUniqueReference();

        try {
          final transferCode = await PaystackService().initiateTransfer(
            amount: amount,
            recipientCode: recipientCode,
            reference: reference,
            selectedBankName: bankName,
            selectedAccountName: accountName,
          );

          print(transferCode);

          if (transferCode != null) {
            Get.snackbar("Withdrawal",
                'Withdrawal successfully. $amount has been transferred to your account');
            print(
                'Paystack transfer initiated successfully. Transfer Code: $transferCode');
          } else {
            print('Withdrawal transaction saved Failed.');
          }
        } catch (error) {
          print("Error: $error");
        }
      } else {
        print('Error: Recipient code is null');
      }
    } catch (error) {
      print('Error initiating bank transfer: $error');
    }
  }

  String _generateUniqueReference() {
    var epochTime = DateTime.now().millisecondsSinceEpoch;
    var random = Random().nextInt(10000);
    var combinedString = 'TXN_$epochTime-$random';
    var bytes = utf8.encode(combinedString);
    var md5Hash = md5.convert(bytes); // Use MD5 hash function
    var hashedReference = md5Hash.toString();
    return "TXN-${hashedReference}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          height: Get.size.height,
          width: Get.size.width,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    Visibility(
                      visible: accountAvailable,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (accountName.isNotEmpty) ? accountName : "",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor: Color(
                                0xFF8C52FF), // Set the background color of the Avatar
                            child: Text(
                              getInitials(accountName) ?? "",
                              style: const TextStyle(
                                fontSize: 18, // Adjust the font size as needed
                                color: Colors.white, // Set the text color
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      controller: accountEditingController,
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(
                            width: 1,
                            color: Colors.grey,
                          ),
                        ),
                        labelText: "Account Number",
                        labelStyle: const TextStyle(color: Colors.black87),
                        hintText: "Enter Account Number",
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      keyboardType: TextInputType.number,
                      //style: pBold16,
                      onChanged: (value) {
                        setState(() {
                          accountName = "";
                          accountNumber = "";
                          accountAvailable = false;
                        });
                        if (bankCode != "") {
                          if (value.length == 10 &&
                              int.tryParse(value) != null) {
                            //fetchRecipient();
                            print('Account Number: $value');
                          } else {
                            //Get.snackbar("", "Invalid account number");
                            print('Phone number length: ${value.length}');
                          }
                        }
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<BanksData>(
                        isExpanded: true,
                        isDense: true,
                        hint: Text(
                          (banks == [])
                              ? 'Fetching banks, please wait...'
                              : 'Select Banks',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        items: banks
                            .map<DropdownMenuItem<BanksData>>((BanksData bank) {
                          return DropdownMenuItem<BanksData>(
                            value: bank,
                            child: Text(
                              bank.name,
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        value: selectedBank,
                        onChanged: (BanksData? value) {
                          setState(() {
                            print(value!.code.toString());
                            bankCode = value.code.toString();
                            selectedBank = value;
                            bankName = value.name;
                            accountNumber = accountEditingController.text;
                          });
                          print("kdjfkdjfkdjfdkfjkdf");
                          print(
                              "$bankCode $bankName $accountNumber $accountName");
                          if (bankCode != "") {
                            if (accountEditingController.text.length == 10 &&
                                int.tryParse(accountEditingController.text) !=
                                    null) {
                              verifyAccountnumber();
                            } else {
                              //Get.snackbar("", "Invalid account number");
                              print('Invalid input: $value');
                            }
                          }
                        },
                        buttonStyleData: ButtonStyleData(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              width: 1,
                              color: Colors.grey,
                            ),
                          ),
                          height: 50,
                          width: Get.size.width,
                        ),
                        dropdownStyleData: DropdownStyleData(
                            maxHeight: Get.size.height / 3,
                            decoration: const BoxDecoration(
                                borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ))),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 40,
                        ),
                        dropdownSearchData: DropdownSearchData(
                          searchController: SearchEditingController,
                          searchInnerWidgetHeight: 50,
                          searchInnerWidget: Container(
                            height: 50,
                            padding: const EdgeInsets.only(
                              top: 8,
                              bottom: 4,
                              right: 8,
                              left: 8,
                            ),
                            child: TextFormField(
                              expands: true,
                              maxLines: null,
                              controller: SearchEditingController,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                hintText: 'Search for an item...',
                                hintStyle: const TextStyle(fontSize: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          searchMatchFn: (item, searchValue) {
                            final myItem = banks.firstWhere((element) =>
                                element.name.toLowerCase() ==
                                item.value!.name.toLowerCase());
                            return myItem.name.contains(searchValue);
                          },
                        ),
                        onMenuStateChange: (isOpen) {
                          if (!isOpen) {
                            SearchEditingController.clear();
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Visibility(
                      visible: accountAvailable,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: TextFormField(
                              controller: amountEditingController,
                              decoration: InputDecoration(
                                prefix: const Text(
                                  '₦ ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                suffix: const Text(
                                  'Min: ₦5000 ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(
                                    width: 1,
                                    color: Colors.grey,
                                  ),
                                ),
                                labelText: "Withdrawal amount",
                                labelStyle:
                                    const TextStyle(color: Colors.black87),
                                hintText: "Enter amount to withdraw",
                                hintStyle: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                              keyboardType: TextInputType.number,
                              validator: amountValidator,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                double amount =
                                    double.parse(amountEditingController.text);
                                _initiatePaystackTransfer(amount);
                              }
                            },
                            child: Text("Withdraw"),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
