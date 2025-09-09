import 'package:flutter/material.dart';
import 'package:smart_isp/features/profile/presentation/profile_page.dart';

class CollectorHomePage extends StatefulWidget {
  const CollectorHomePage({super.key});

  @override
  State<CollectorHomePage> createState() => _CollectorHomePageState();
}

class _CollectorHomePageState extends State<CollectorHomePage> {
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
      backgroundColor: Colors.grey[200],

      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Collector",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 44,
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Search (Name or Phone)",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _buildDropdown("Filter by Month", ["January", "February", "March"], selectedMonth,
                        (val) {
                      setState(() => selectedMonth = val);
                    }),
                const SizedBox(height: 12),
                _buildDropdown("Filter by Status", ["All", "Paid", "Unpaid"], selectedStatus,
                        (val) {
                      setState(() => selectedStatus = val);
                    }),
                const SizedBox(height: 12),
                _buildDropdown("Filter by Distance", ["Near", "Far"], selectedDistance, (val) {
                  setState(() => selectedDistance = val);
                }),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      Text("Paid: 0",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text("Unpaid: 0",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      debugPrint("${client["name"]} tapped");
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(client["name"],
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  children: const [
                                    Icon(Icons.sim_card_rounded,
                                        size: 16, color: Colors.black54),
                                    SizedBox(width: 4),
                                    Text("DITO: 09*******76",
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      client["status"] == "Paid"
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 16,
                                      color: client["status"] == "Paid"
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Status: ${client["status"]}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: client["status"] == "Paid"
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 16, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Text("${client["distance"]} Away",
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.blue)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 18, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isFabOpen) ...[
              _buildMiniFab(Icons.map, "Map Client", () {
                debugPrint(" Map Client tapped");
              }),
              const SizedBox(height: 10),
              _buildMiniFab(Icons.restart_alt, "Reboot", () {
                debugPrint("Reboot tapped");
              }),
              const SizedBox(height: 10),
              _buildMiniFab(Icons.person, "Profile", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Profile()),
                );
              }),
              const SizedBox(height: 10),
              _buildMiniFab(Icons.print, "Print", () {
                debugPrint("Print tapped");
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

  Widget _buildDropdown(
      String hint, List<String> items, String value, Function(String) onSelected) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                hint,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.map((item) {
                  return ListTile(
                    title: Text(item, style: const TextStyle(fontFamily: 'Poppins')),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        onSelected(item);
                      });
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value, style: const TextStyle(fontSize: 14, fontFamily: 'Poppins')),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniFab(IconData icon, String tooltip, VoidCallback onPressed) {
    return SizedBox(
      width: 55,
      height: 55,
      child: FloatingActionButton(
        heroTag: tooltip,
        mini: true,
        onPressed: onPressed,
        backgroundColor: Colors.lightBlue,
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
