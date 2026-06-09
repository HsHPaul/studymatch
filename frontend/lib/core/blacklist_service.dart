import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Blacklist {
  final List<String> email;
  final List<String> chat;

  const Blacklist({required this.email, required this.chat});

  factory Blacklist.fromJson(Map<String, dynamic> json) => Blacklist(
        email: List<String>.from(json['email'] as List? ?? []),
        chat: List<String>.from(json['chat'] as List? ?? []),
      );

  String? checkEmail(String value) {
    final lower = value.toLowerCase();
    for (final term in email) {
      if (lower.contains(term.toLowerCase())) {
        return 'Diese E-Mail-Adresse ist nicht erlaubt.';
      }
    }
    return null;
  }

  String? checkChat(String value) {
    final lower = value.toLowerCase();
    for (final term in chat) {
      if (lower.contains(term.toLowerCase())) {
        return 'Diese Nachricht enthält unerlaubte Inhalte.';
      }
    }
    return null;
  }
}

final blacklistProvider = FutureProvider<Blacklist>((ref) async {
  final raw = await rootBundle.loadString('assets/blacklist.json');
  return Blacklist.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});
