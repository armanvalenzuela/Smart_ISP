import 'package:flutter/material.dart';
import 'package:smart_isp/features/auth/presentation/login_screen.dart';
import 'package:smart_isp/features/profile/presentation/profile_page.dart';

class CollectorHomePage extends StatefulWidget {
  const CollectorHomePage({super.key});

  @override
  State<CollectorHomePage> createState() => _CollectorHomePageState();
}

class _CollectorHomePageState extends State<CollectorHomePage>
    with SingleTickerProviderStateMixin {
  String selectedMonth = "January";
  String selectedStatus = "All";
  String selectedDistance = "Near";

  bool _isFabOpen = false;

  final List<Map<String, dynamic>> clients = [
    {"name": "Juan Dela Cruz", "status": "Paid", "distance": "200m"},
    {"name": "Maria Santos", "status": "Unpaid", "distance": "500m"},
    {"name": "Pedro Gomez", "status": "Unpaid", "distance": "1.2km"},
    {"name": "Andres Bonifacio", "status": "Paid", "distance": "1.5km"},
    {"name": "Emilio Jacinto", "status": "Paid", "distance": "3.7km"},
    {"name": "Diana Cortez", "status": "Unpaid", "distance": "1.2km"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Collector"),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 🔍 Search bar
            TextField(
              decoration: InputDecoration(
                hintText: "Search client...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ⏬ Filters Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDropdown("Month", ["January", "February", "March"],
                    selectedMonth, (val) {
                      setState(() => selectedMonth = val!);
                    }),
                const SizedBox(width: 8),
                _buildDropdown(
                    "Status", ["All", "Paid", "Unpaid"], selectedStatus, (val) {
                  setState(() => selectedStatus = val!);
                }),
                const SizedBox(width: 8),
                _buildDropdown(
                    "Distance", ["Near", "Far"], selectedDistance, (val) {
                  setState(() => selectedDistance = val!);
                }),
              ],
            ),
            const SizedBox(height: 12),

            // 📋 Client List
            Expanded(
              child: ListView.builder(
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: client["status"] == "Paid"
                            ? Colors.green
                            : Colors.red,
                        child: Icon(
                          client["status"] == "Paid"
                              ? Icons.check
                              : Icons.close,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(client["name"]),
                      subtitle:
                      Text("${client["status"]} • ${client["distance"]}"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // 👉 Navigate to Client Details
                        // Navigator.pushNamed(context, "/client_details");
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ✅ Floating Action Button with 4 expanding buttons
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isFabOpen) ...[
              _buildMiniFab(Icons.map, "Add Client", () {
                debugPrint("Add Client tapped");
              }),
              const SizedBox(height: 10),
              _buildMiniFab(Icons.restart_alt, "Payments", () {
                debugPrint("Payments tapped");
              }),
              const SizedBox(height: 10),
              _buildMiniFab(Icons.person, "Profile", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Profile()),
                );
              }),
              const SizedBox(height: 10),
              _buildMiniFab(Icons.print, "Settings", () {
                debugPrint("Settings tapped");
              }),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: 70,
              height: 70,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _isFabOpen = !_isFabOpen;
                  });
                },
                backgroundColor: Colors.blue,
                child: Icon(
                  _isFabOpen ? Icons.close : Icons.menu,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔽 Reusable Dropdown widget
  Widget _buildDropdown(String label, List<String> items, String value,
      Function(String?) onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        items: items
            .map((item) =>
            DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // 🔹 Reusable Mini FAB button
  Widget _buildMiniFab(IconData icon, String tooltip, VoidCallback onPressed) {
    return SizedBox(
      width: 55,
      height: 55,
      child: FloatingActionButton(
        heroTag: tooltip, // unique heroTag
        mini: true,
        onPressed: onPressed,
        backgroundColor: Colors.lightBlue,
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
