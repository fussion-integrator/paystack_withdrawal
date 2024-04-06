// To parse this JSON data, do
//
//     final banksResponse = banksResponseFromJson(jsonString);

import 'dart:convert';

BanksResponse banksResponseFromJson(String str) =>
    BanksResponse.fromJson(json.decode(str));

String banksResponseToJson(BanksResponse data) => json.encode(data.toJson());

class BanksResponse {
  bool status;
  String message;
  List<BanksData> data;

  BanksResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory BanksResponse.fromJson(Map<String, dynamic> json) => BanksResponse(
        status: json["status"],
        message: json["message"],
        data: List<BanksData>.from(
            json["data"].map((x) => BanksData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class BanksData {
  int id;
  String name;
  String slug;
  String code;
  String longcode;
  String? gateway;
  bool payWithBank;
  bool active;
  String country;
  String currency;
  String type;
  bool isDeleted;
  DateTime createdAt;
  DateTime updatedAt;

  BanksData({
    required this.id,
    required this.name,
    required this.slug,
    required this.code,
    required this.longcode,
    required this.gateway,
    required this.payWithBank,
    required this.active,
    required this.country,
    required this.currency,
    required this.type,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BanksData.fromJson(Map<String, dynamic> json) => BanksData(
        id: json["id"],
        name: json["name"],
        slug: json["slug"],
        code: json["code"],
        longcode: json["longcode"],
        gateway: json["gateway"],
        payWithBank: json["pay_with_bank"],
        active: json["active"],
        country: json["country"],
        currency: json["currency"],
        type: json["type"],
        isDeleted: json["is_deleted"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "slug": slug,
        "code": code,
        "longcode": longcode,
        "gateway": gateway,
        "pay_with_bank": payWithBank,
        "active": active,
        "country": country,
        "currency": currency,
        "type": type,
        "is_deleted": isDeleted,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
      };
}
