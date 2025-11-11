/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {v2 as cloudinary} from "cloudinary";
import * as logger from "firebase-functions/logger";

admin.initializeApp();

// --- Konfigurasi Cloudinary ---
// Pastikan untuk mengganti ini dengan nilai asli Anda
cloudinary.config({
  cloud_name: "dwzyymvce",
  api_key: "278265395675589",
  api_secret: "id2wRGY0jd2sOAst6jfIipMHJgs",
});

interface DeletePhotoData {
  publicId: string;
}

// Interface ini masih berguna untuk dokumentasi dan kejelasan kode
// interface DeletePhotoResult {
//   success: boolean;
//   message: string;
// }

// --- Fungsi Cloud Function v2 ---
// HAPUS generic type kedua (<DeletePhotoResult>) dari sini
export const deleteCloudinaryPhoto = onCall<DeletePhotoData>(
  async (request) => {
    const {data, auth} = request;

    // 1. Verifikasi Otentikasi
    if (!auth) {
      throw new HttpsError(
        "unauthenticated",
        "Fungsi ini harus dipanggil oleh pengguna yang terotentikasi."
      );
    }

    // 2. Ambil dan validasi publicId
    const publicId = data?.publicId;

    if (!publicId || typeof publicId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "Parameter 'publicId' wajib diisi dan harus berupa string."
      );
    }

    try {
      // 3. Hapus foto dari Cloudinary
      const result = await cloudinary.uploader.destroy(publicId);

      if (result.result !== "ok" && result.result !== "not found") {
        logger.error(`Gagal menghapus ID ${publicId}: ${result.result}`);
        throw new HttpsError(
          "internal",
          `Gagal menghapus foto di Cloudinary. Status: ${result.result}`
        );
      }

      return {
        success: true,
        message: `Foto ${publicId} berhasil dihapus atau tidak ditemukan.`,
      };
    } catch (error) {
      logger.error("Error saat menghapus foto Cloudinary:", error);
      // Jika error berasal dari HttpsError, lempar kembali
      if (error instanceof HttpsError) {
        throw error;
      }
      // Untuk error lainnya, bungkus dalam HttpsError
      throw new HttpsError(
        "unknown",
        "Terjadi kesalahan saat berkomunikasi dengan Cloudinary."
      );
    }
  }
);


// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
// setGlobalOptions({ maxInstances: 10 });

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
