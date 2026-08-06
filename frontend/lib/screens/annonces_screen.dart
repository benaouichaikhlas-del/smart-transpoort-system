import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';

class AnnoncesScreen extends StatefulWidget {
  const AnnoncesScreen({super.key});
  @override
  State<AnnoncesScreen> createState() => _AnnoncesScreenState();
}

class _AnnoncesScreenState extends State<AnnoncesScreen> {
  List<dynamic> _annonces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _token => context.read<AuthProvider>().user!.token;

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final r = await http.get(
        Uri.parse(ApiConstants.annonces),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (r.statusCode == 200) setState(() => _annonces = jsonDecode(r.body));
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _showEnvoyerDialog() async {
    final titreCtrl = TextEditingController();
    final contenuCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.campaign, color: AppTheme.warning),
            SizedBox(width: 8),
            Text(
              'Envoyer une annonce',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titreCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Titre',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.title, color: Colors.white38),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contenuCtrl,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Contenu de l\'annonce...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final r = await http.post(
                Uri.parse(ApiConstants.annonces),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $_token',
                },
                body: jsonEncode({
                  'titre': titreCtrl.text.trim(),
                  'contenu': contenuCtrl.text.trim(),
                }),
              );
              if (!mounted) return;

              // <-- CHANGED #1: null-safe message
              final body = jsonDecode(r.body);
              final message = body['message']?.toString() ?? 'Erreur inconnue';

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor:
                      r.statusCode == 201 ? Colors.green : Colors.red,
                ),
              );
              if (r.statusCode == 201) _load();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: const BackButton(color: Colors.white),
        title: const Text('Annonces', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_annonce',
        onPressed: _showEnvoyerDialog,
        backgroundColor: AppTheme.warning,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: const Text('Envoyer', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _annonces.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 70,
                        color: Colors.white24,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucune annonce',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _annonces.length,
                  itemBuilder: (_, i) {
                    final a = _annonces[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.campaign,
                                color: AppTheme.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  // <-- CHANGED #2: null-safe titre
                                  a['titre']?.toString() ?? 'Sans titre',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                onPressed: () async {
                                  final r = await http.delete(
                                    Uri.parse(
                                      '${ApiConstants.annonces}/${a['id']}',
                                    ),
                                    headers: {
                                      'Authorization': 'Bearer $_token'
                                    },
                                  );
                                  if (!mounted) return;

                                  // <-- CHANGED #3: null-safe message
                                  final body = jsonDecode(r.body);
                                  final message = body['message']?.toString() ??
                                      'Erreur inconnue';

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      backgroundColor: r.statusCode == 200
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  );
                                  if (r.statusCode == 200) _load();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            // <-- CHANGED #4: null-safe contenu
                            a['contenu']?.toString() ?? '',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            a['created_at']?.toString().substring(0, 10) ?? '',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
