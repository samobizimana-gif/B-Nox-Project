import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/bnox_toast.dart'; // <-- IMPORT

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0B1020) : Colors.white;

    final features = [
      _Feature(icon: Icons.insert_drive_file_outlined, title: 'Fichiers', subtitle: 'Partage vérifié par empreinte SHA-256.', color: BnoxColors.cyan),
      _Feature(icon: Icons.camera_alt_outlined, title: 'B-NOX CAM', subtitle: 'Photos horodatées et preuves de provenance.', color: BnoxColors.violet),
      _Feature(icon: Icons.wifi_off, title: 'Hors-ligne', subtitle: 'Échange local via Bluetooth ou Wi-Fi Direct.', color: BnoxColors.purple),
      _Feature(icon: Icons.history, title: 'B-NOX LOG', subtitle: 'Historique de sécurité vérifiable.', color: BnoxColors.cyan),
      _Feature(icon: Icons.phone_outlined, title: 'Appels', subtitle: 'Audio et vidéo chiffrés de bout en bout.', color: BnoxColors.violet),
      _Feature(icon: Icons.groups_outlined, title: 'Groupes', subtitle: 'Conversations privées en groupe.', color: BnoxColors.cyan),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                      children: const [
                        TextSpan(text: 'B-'),
                        TextSpan(text: 'NOX', style: TextStyle(color: BnoxColors.cyan)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.shield_outlined, color: BnoxColors.cyan, size: 24),
                  
                ],
              ),
              
              const SizedBox(height: 20),
              
              Text('Découvrir', style: TextStyle(color: textColor, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Les prochaines fonctionnalités de B-NOX.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 10),
              Container(width: 40, height: 3, decoration: BoxDecoration(color: BnoxColors.cyan, borderRadius: BorderRadius.circular(2))),

              const SizedBox(height: 16),
              
              Expanded(
                child: GridView.builder(
                  itemCount: features.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.95, 
                  ),
                  itemBuilder: (context, index) {
                    final f = features[index];
                    return InkWell( // <-- AJOUT DU CLIC
                      onTap: () {
                        BnoxToast.show(context, 'La fonctionnalité "${f.title}" arrive bientôt !', icon: f.icon);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: f.color.withOpacity(0.1), 
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(f.icon, color: f.color, size: 18),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: BnoxColors.cyan.withOpacity(0.15), 
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('BIENTÔT', style: TextStyle(color: BnoxColors.cyan, fontSize: 7, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              f.title, 
                              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              f.subtitle, 
                              style: const TextStyle(color: Colors.grey, fontSize: 10, height: 1.2),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Icon(Icons.arrow_forward, color: BnoxColors.cyan, size: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  _Feature({required this.icon, required this.title, required this.subtitle, required this.color});
}