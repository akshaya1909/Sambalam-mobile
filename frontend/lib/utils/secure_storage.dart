import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  factory SecureStorage() {
    return _instance;
  }

  SecureStorage._internal();

  // Store a value securely
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Read a value securely
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  // Delete a value
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  // Delete all values
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // Hash a PIN for secure storage
  String hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verify a PIN against a stored hash
  bool verifyPin(String inputPin, String storedHash, String salt) {
    final inputHash = hashPin(inputPin, salt);
    return inputHash == storedHash;
  }

  // Generate a random salt
  String generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  // Store a PIN securely with salt
  Future<void> storePin(String pin) async {
    final salt = generateSalt();
    final hashedPin = hashPin(pin, salt);
    await write('pin_hash', hashedPin);
    await write('pin_salt', salt);
  }

  // Verify a PIN against the stored hash
  Future<bool> verifyStoredPin(String inputPin) async {
    final storedHash = await read('pin_hash');
    final salt = await read('pin_salt');
    
    if (storedHash == null || salt == null) {
      return false;
    }
    
    return verifyPin(inputPin, storedHash, salt);
  }
}