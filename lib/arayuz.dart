import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

class Arayuz extends StatefulWidget {
  const Arayuz({super.key});

  @override
  State<Arayuz> createState() => _ArayuzState();
}

// Platforma göre API base URL belirleme
String _getApiBaseUrl() {
  const port = 5001;
  return 'http://10.0.2.2:$port';
}

// API bağlantısını test eden fonksiyon
Future<bool> testApiBaglantisi() async {
  final baseUrl = _getApiBaseUrl();
  print("API testi URL: $baseUrl/soru");

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/soru'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'soru': 'test'}),
    );

    print("Test status code: ${response.statusCode}");
    print("Test response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.containsKey('cevap')) {
        return true;
      }
    }
    return false;
  } catch (e) {
    print("API bağlantı testi hatası: $e");
    return false;
  }
}

class _ArayuzState extends State<Arayuz> {
  final TextEditingController _girdiController = TextEditingController();
  final List<Map<String, String>> _mesajlar = [];

  bool _baglantiDurumu = true;

  @override
  void initState() {
    super.initState();
    testApiBaglantisi().then((baglantiBasarili) {
      setState(() {
        _baglantiDurumu = baglantiBasarili;
      });

      if (baglantiBasarili) {
        print("API bağlantısı başarılı!");
      } else {
        print("API bağlantısı başarısız!");
      }
    });
  }

  Future<String> _csvdenCevapAl(String soru) async {
    final baseUrl = _getApiBaseUrl();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/soru'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'soru': soru}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['cevap'];
      } else {
        return "Sunucu hatası: ${response.statusCode}";
      }
    } catch (e) {
      print("Hata detayları: $e");
      return "Bağlantı hatası: $e";
    }
  }

  void _mesajGonder() async {
    String girdi = _girdiController.text.trim();
    if (girdi.isEmpty) return;

    setState(() {
      _mesajlar.add({'rol': 'kullanıcı', 'metin': girdi});
    });

    String cevap = await _csvdenCevapAl(girdi);

    setState(() {
      _mesajlar.add({'rol': 'bot', 'metin': cevap});
      _girdiController.clear();
    });
  }

  Widget _chatBaloncugu(String rol, String metin) {
    bool kullaniciMi = rol == 'kullanıcı';
    return Align(
      alignment: kullaniciMi ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
        kullaniciMi ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!kullaniciMi)
            const CircleAvatar(
              backgroundImage: AssetImage('assets/images/bot.png'),
              radius: 18,
            ),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft:
                kullaniciMi ? Radius.circular(16) : Radius.zero,
                bottomRight:
                kullaniciMi ? Radius.zero : Radius.circular(16),
              ),
            ),
            child: Text(
              metin,
              style: const TextStyle(color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          if (kullaniciMi)
            const CircleAvatar(
              backgroundImage: AssetImage('assets/images/user.png'),
              radius: 18,
            ),
        ],
      ),
    );
  }

  Widget _inputAlani() {
    return Container(
      color: Colors.indigo[800],
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _girdiController,
                style: const TextStyle(color: Colors.black),
                onSubmitted: (_) => _mesajGonder(),
                decoration: const InputDecoration(
                  hintText: 'Sorunuzu yazın...',
                  hintStyle: TextStyle(color: Colors.black54),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.indigo[600],
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _mesajGonder,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[900],
      appBar: AppBar(
        backgroundColor: Colors.indigo[400],
        title: const Text(
          'SoruBotu',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_baglantiDurumu)
              Container(
                color: Colors.red[400],
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'API bağlantısı kurulamadı. Lütfen sunucuyu kontrol edin.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _mesajlar.length,
                padding: const EdgeInsets.all(12),
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final mesaj = _mesajlar[index];
                  return _chatBaloncugu(mesaj['rol']!, mesaj['metin']!);
                },
              ),
            ),
            const Divider(height: 1),
            _inputAlani(),
          ],
        ),
      ),
    );
  }
}

