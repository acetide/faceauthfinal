class User {
  final String userName;
  final String name;
  final String kodeNik;
  final String email;
  final String jabatan;
  final String bagian;
  final String namaCabang;
  final String namaKoperasi;
  final String? kodeCabang;
  final String? kodeAO;
  final String? imageUser;

  User({
    required this.userName,
    required this.name,
    required this.kodeNik,
    required this.email,
    required this.jabatan,
    required this.bagian,
    required this.namaCabang,
    required this.namaKoperasi,
    this.kodeCabang,
    this.kodeAO,
    this.imageUser,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userName: json['userName'] ?? '',
      name: json['Name'] ?? json['name'] ?? '',
      kodeNik: json['KodeNik'] ?? json['kodeNik'] ?? '',
      email: json['Email'] ?? json['email'] ?? '',
      jabatan: json['Jabatan'] ?? json['jabatan'] ?? '',
      bagian: json['Bagian'] ?? json['bagian'] ?? '',
      namaCabang: json['NamaCabang'] ?? json['namaCabang'] ?? '',
      namaKoperasi: json['NamaKoperasi'] ?? json['namaKoperasi'] ?? '',
      kodeCabang: json['KodeCabang'] ?? json['kodeCabang'],
      kodeAO: json['Kode_AO'] ?? json['kodeAO'],
      imageUser: json['Image_User'] ?? json['imageUser'],
    );
  }
}
