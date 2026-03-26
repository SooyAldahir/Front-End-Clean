import '../network/api_client.dart';

/// Convierte rutas relativas del servidor en URLs absolutas.
/// Las URLs de Cloudinary/S3 (https://) se devuelven intactas.
String toAbsoluteUrl(String? raw) {
  if (raw == null || raw.isEmpty || raw == 'null') return '';
  final s = raw.trim();
  if (s.isEmpty || s == 'null') return '';

  if (s.startsWith('http://') || s.startsWith('https://')) return s;

  var path = s.replaceAll('\\', '/');

  final idxPublic = path.indexOf('public/uploads/');
  if (idxPublic != -1) path = path.substring(idxPublic + 'public'.length);

  final idxUploads = path.indexOf('/uploads/');
  if (idxUploads != -1) {
    path = path.substring(idxUploads);
  } else if (path.startsWith('uploads/')) {
    path = '/$path';
  } else if (!path.startsWith('/')) {
    path = '/$path';
  }

  return '${ApiClient.baseUrl}$path';
}
