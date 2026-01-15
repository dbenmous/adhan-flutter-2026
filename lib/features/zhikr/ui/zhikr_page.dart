import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZhikrPage extends StatefulWidget {
  const ZhikrPage({super.key});

  @override
  State<ZhikrPage> createState() => _ZhikrPageState();
}

class _ZhikrPageState extends State<ZhikrPage> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _count = prefs.getInt('zhikr_count') ?? 0;
    });
  }

  Future<void> _incrementCount() async {
    setState(() {
      _count++;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('zhikr_count', _count);
  }

  Future<void> _resetCount() async {
    setState(() {
      _count = 0;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('zhikr_count', 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Digital Tasbeeh', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _resetCount,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: InkWell(
        onTap: _incrementCount,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 10,
                    )
                  ],
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 4,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_count',
                      style: GoogleFonts.outfit(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      'Praises',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Tap anywhere to count',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
