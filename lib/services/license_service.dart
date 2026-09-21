import 'dart:convert';
import 'dart:io';
// import 'dart:typed_data';
import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';
import 'package:flutter/foundation.dart';

class LicenseStatus {
  final bool isValid;
  final DateTime? expiry;
  final String? client;
  final String? errorMessage;

  LicenseStatus({
    required this.isValid,
    this.expiry,
    this.client,
    this.errorMessage,
  });

  int get daysRemaining {
    if (expiry == null) return 0;
    return expiry!.difference(DateTime.now()).inDays;
  }
}

class LicenseService {
  // Embedded public key — replace this with the contents of license_public.pem
  static const String _publicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyZR6bXcd4kDQz+mUFSMJ
6u+uyEAzvno3zEd0lhefNMw7++RILOrhU/s/xP44wblDmyZYz2Kgq13f15rkbi3G
8fXYHTKzZBqQS3f3kJ+5VOXwMTWriGTsZNb3Llo0INnytVDP32Q+FPt4EAQP69Ks
9ljSJEw+rqB6irGk7jBFxdSMM+pDfa5ei61YwjQSEQ02w6BKiH/e7e8E4nkOWbz4
uZlDn7CHgG1mJgE15V4r/KUPydELMZKjFS6QTLRTnUDmhSW57vqfT2pZZIDCChWn
iPFxyE99tTQzo+B1HRHEZRIR+c7X1gMlagL9hsmRcL4M7R17mwnEuGuRjJAcZLwE
pwIDAQAB
-----END PUBLIC KEY-----
''';

  // Where the app looks for the license file (next to the .exe)
  static String get _licenseFilePath {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return '$exeDir/license.key';
  }

    static Future<LicenseStatus> checkLicense() async {
    if (kIsWeb) {
      return LicenseStatus(
        isValid: true,
        client: 'Web',
        expiry: DateTime(2099, 12, 31),
      );
    }

    try {
      final file = File(_licenseFilePath);
      if (!file.existsSync()) {
        return LicenseStatus(
          isValid: false,
          errorMessage: 'License file not found',
        );
      }

      final licenseContent = file.readAsStringSync().trim();
      final parts = licenseContent.split('.');
      if (parts.length != 2) {
        return LicenseStatus(
          isValid: false,
          errorMessage: 'Malformed license file',
        );
      }

      final payloadB64 = parts[0];
      final signatureB64 = parts[1];

      final payload = utf8.decode(base64.decode(payloadB64));
      final signature = base64.decode(signatureB64);

      final isValidSignature = _verifySignature(payload, signature);
      if (!isValidSignature) {
        return LicenseStatus(
          isValid: false,
          errorMessage: 'Invalid license signature',
        );
      }

      final payloadMap = jsonDecode(payload) as Map<String, dynamic>;
      final expiryStr = payloadMap['expiry'] as String?;
      final client = payloadMap['client'] as String?;

      if (expiryStr == null) {
        return LicenseStatus(
          isValid: false,
          errorMessage: 'License has no expiry',
        );
      }

      final expiry = DateTime.parse(expiryStr);
      final isNotExpired = expiry.isAfter(DateTime.now());

      return LicenseStatus(
        isValid: isNotExpired,
        expiry: expiry,
        client: client,
        errorMessage: isNotExpired ? null : 'License expired',
      );
    } catch (e) {
      return LicenseStatus(
        isValid: false,
        errorMessage: 'Error reading license: $e',
      );
    }
  }


  static bool _verifySignature(String payload, List<int> signatureBytes) {
    try {
      final publicKey = CryptoUtils.rsaPublicKeyFromPem(_publicKeyPem);
      final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');
      verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
      final sig = RSASignature(Uint8List.fromList(signatureBytes));
      return verifier.verifySignature(utf8.encode(payload), sig);
    } catch (e) {
      print('Signature verification error: $e');
      return false;
    }
  }
}
