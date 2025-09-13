import 'package:flutter/material.dart';
import 'package:smart_isp/features/collector/map_screen.dart';
import 'package:smart_isp/features/profile/presentation/profile_page.dart';

class CollectorHomePage extends StatefulWidget {
  const CollectorHomePage({super.key});

  @override
  State<CollectorHomePage> createState() => _CollectorHomePageState();
}

class _CollectorHomePageState extends State<CollectorHomePage> {
  String selectedStatus = "All";

  bool _isFabOpen = false;

  final List<Map<String, dynamic>> clients = [
    {"name": "Juan Dela Cruz", "status": "Active", "distance": "200m"},
    {"name": "Maria Santos", "status": "Inactive", "distance": "500m"},
    {"name": "Pedro Gomez", "status": "Inactive", "distance": "1.2km"},
    {"name": "Andres Bonifacio", "status": "Active", "distance": "1.5km"},
    {"name": "Emilio Jacinto", "status": "Active", "distance": "3.7km"},
    {"name": "Diana Cortez", "status": "Inactive", "distance": "1.2km"},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredClients = selectedStatus == "All"
        ? clients
        : clients.where((c) => c["status"] == selectedStatus).toList();

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

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44,
                        child: TextField(
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                          decoration: InputDecoration(
                            hintText: "Search",
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 44,
                        child: _buildDropdown(
                          "Filter by Status",
                          ["All", "Active", "Inactive"],
                          selectedStatus,
                              (val) {
                            setState(() => selectedStatus = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      Text(
                        "Paid: 0",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Unpaid: 0",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
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
              itemCount: filteredClients.length,
              itemBuilder: (context, index) {
                final client = filteredClients[index];
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
                                Text(
                                  client["name"],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.sim_card_rounded,
                                      size: 16,
                                      color: Colors.black54,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "DITO: 09*******76",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      client["status"] == "Active"
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 16,
                                      color: client["status"] == "Active"
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Status: ${client["status"]}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: client["status"] == "Active"
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${client["distance"]} Away",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: Colors.black54,
                          ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                );
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
      String hint,
      List<String> items,
      String value,
      Function(String) onSelected,
      ) {
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
                    title: Text(
                      item,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                      ),
                    ),
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
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value.isEmpty ? hint : value,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Colors.black54,
            ),
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
