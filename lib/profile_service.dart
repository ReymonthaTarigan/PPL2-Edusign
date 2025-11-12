import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ProfilePhotoService {
  // Ganti dengan detail akun Cloudinary Anda yang sebenarnya!
  static const String _cloudName = 'dwzyymvce';
  static const String _uploadPreset = 'profile_photo';
  
  // URL endpoint Cloudinary untuk mengunggah
  static final Uri _cloudinaryUploadUrl =
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

  // URL endpoint Cloudinary untuk menghapus
  // (CATATAN: Hapus memerlukan API Secret, yang TIDAK BOLEH DITARUH DI KODE FRONTEND/CLIENT)
  // Untuk aplikasi Flutter/Mobile, Anda HARUS menggunakan Fungsi Cloud (Cloud Function)
  // sebagai perantara yang aman untuk operasi penghapusan.
  // Implementasi ini mengasumsikan Anda akan menggunakan Cloud Function untuk penghapusan
  // atau hanya mengandalkan Public ID untuk mengelola (meski kurang ideal).

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> _deleteOldPhoto(String publicId) async {
    try {
      // Panggil Cloud Function deleteCloudinaryPhoto
      final result = await _functions.httpsCallable('deleteCloudinaryPhoto').call({
        'publicId': publicId,
      });

      print('Hasil penghapusan Cloudinary: ${result.data['message']}');
    } on FirebaseFunctionsException catch (e) {
      // Tangani error dari Cloud Function (misalnya unauthenticated, invalid-argument)
      print('Error memanggil Cloud Function untuk penghapusan: ${e.code} - ${e.message}');
      // Kita lanjutkan proses update meskipun penghapusan gagal, agar user tetap bisa update foto baru
    } catch (e) {
      print('Error tak terduga saat menghapus foto lama: $e');
    }
  }

  /// 📤 Mengunggah atau memperbarui foto profil.
  ///
  /// Proses:
  /// 1. Dapatkan publicId lama dari Firestore (untuk penghapusan).
  /// 2. Hapus foto lama di Cloudinary (memerlukan Cloud Function/server-side yang aman).
  /// 3. Unggah foto baru ke Cloudinary.
  /// 4. Simpan URL baru dan publicId di Firestore.
  Future<String> uploadAndUpdatePhoto({
    required String uid,
    required File imageFile,
  }) async {
    // 1. Dapatkan Public ID lama dari Firestore
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final oldPublicId = userDoc.data()?['photoPublicId'] as String?;

    // 2. Jika ada foto lama, coba hapus (Asumsi: Anda punya Cloud Function/Server-side)
    if (oldPublicId != null && oldPublicId.isNotEmpty) {
      await _deleteOldPhoto(oldPublicId);
      print('Mencoba menghapus foto lama dengan Public ID: $oldPublicId');
    }

    // 3. Unggah foto baru ke Cloudinary
    final publicId = '${uid}_photo';

    final uploadRequest = http.MultipartRequest('POST', _cloudinaryUploadUrl)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['public_id'] = publicId // Format: uid_photo
      ..fields['folder'] = 'profile_photos' // Opsional: folder di Cloudinary
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ));

    final streamedResponse = await uploadRequest.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Gagal mengunggah foto ke Cloudinary. Status: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final String secureUrl = data['secure_url'];
    final String newPublicId = data['public_id'];
    
    // 4. Simpan URL baru dan Public ID di Firestore
    await _firestore.collection('users').doc(uid).set({
      'photoUrl': secureUrl,
      'photoPublicId': newPublicId,
    }, SetOptions(merge: true));

    return secureUrl;
  }

  /// 🔄 Mendapatkan URL foto profil pengguna dari Firestore.
  Future<String?> getProfilePhotoUrl(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.data()?['photoUrl'] as String?;
  }
}