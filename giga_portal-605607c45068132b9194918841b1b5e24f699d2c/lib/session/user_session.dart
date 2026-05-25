class UserSession {
  final String username;
  final String name;
  final String email;
  final String kodeNik;
  final String bagian;
  final String kodeCabang;
  final String namaCabang;
  final String namaKoperasi;
  final String jabatan;
  final String? imageUser;

  UserSession({
    required this.username,
    required this.name,
    required this.email,
    required this.kodeNik,
    required this.bagian,
    required this.kodeCabang,
    required this.namaCabang,
    required this.namaKoperasi,
    required this.jabatan,
    this.imageUser,
  });
}

/// TEMP global session (later replace with provider / storage)
UserSession? currentUser;
